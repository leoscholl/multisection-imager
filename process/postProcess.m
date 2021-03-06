function postProcess(store, datadir, subject, varargin)
% postProcess Make stitched images from the raw acquisition in store

p = inputParser();
p.addOptional('makeFlats', '');
p.addOptional('defaultFlats', '', @ischar);
p.addOptional('doAsc', false);
p.addOptional('doCellCount', false);
p.addOptional('rgb', false);
p.addOptional('cellCountChannelPairs', {'mCherry', 'GFP'});
p.addParameter('segmentOnly', false);
p.parse(varargin{:});

% Start waitbar
wb = waitbar(0, 'Loading images and metadata...', 'Name', 'Exporting...'); 
set(wb, 'Tag', 'waitbar');

try
    % Load any existing metadata
    [path, filename, ~] = fileparts(char(store.getSavePath));
    metafile = fullfile(path, filename, sprintf('%s.mat', filename));
    if exist(metafile, 'file')
        load(metafile, 'metadata');
    end

    if p.Results.segmentOnly && ...
            exist('metadata', 'var') && ...
            isfield(metadata, 'rois')
        % Already segmented, skip
        delete(wb);
        return;
    end

    % Load images
    if p.Results.segmentOnly; datatype = 'uint8';
    else; datatype = 'uint16'; end
    if exist('metadata', 'var')
        img = imagesFromDatastore(store, datatype);
    else
        [img, metadata] = imagesFromDatastore(store, datatype);
    end

    % Optionally just do segmentation and quit
    if p.Results.segmentOnly
        waitbar(0.5, wb, 'Segmenting...');
        metadata = segmentSlide(img, metadata);
        exportMetadata(metadata, metafile);
        delete(wb);
        return
    end

    % Do a quick segmentation if there is none
    waitbar(0.2, wb, 'Segmenting (rough)...'); 
    if ~isfield(metadata, 'sections') || ~isfield(metadata, 'rois') || ...
            isempty(metadata.sections) || isempty(metadata.rois)
        roughMetadata = segmentSlide(img, metadata, [], false);
    else
        roughMetadata = metadata;
    end

    % Flat field
    waitbar(0.3, wb, 'Flat-fielding...'); 
    flats = [];
    background = [];
    try
        flats = zeros(size(img,1),size(img,2),size(img,3),'like',img);
        m = load(p.Results.defaultFlats);
        for c = 1:size(img,3)
            channelName = metadata.channels{c};
            flats(:,:,c) = m.flatfields.(channelName);
        end
        background = m.background;
    catch
        flats = [];
        background = [];
    end
    if isfield(metadata, 'flats') && ~isempty(metadata.flats)
        flats = metadata.flats;
    end
    makeFlats = p.Results.makeFlats;
    if ~islogical(makeFlats)
        % by default only if image is large
        makeFlats = ~isfield(metadata, 'flats') && size(img,4) > 500; 
    end
    if makeFlats || isempty(flats)
        flats = generateFlats(img, roughMetadata);
    end
    metadata.flats = flats;
    metadata.background = background;
    img = batchFlatfield(img, flats, background);

    % Normalize and downsample
    waitbar(0.4, wb, 'Normalizing...'); 
    img = imgNormalize(img, roughMetadata);

    % Segment
    waitbar(0.5, wb, 'Segmenting...'); 
    if ~isfield(metadata, 'sections') || ~isfield(metadata, 'rois') || ...
            isempty(metadata.sections) || isempty(metadata.rois)
        metadata = segmentSlide(img, metadata);
    end

    % Find blobs
    if p.Results.doCellCount && isfield(metadata, 'boundaries')
        waitbar(0.6, wb, 'Counting cells...'); 
        metadata = countCells(img, metadata, p.Results.cellCountChannelPairs);
    end

    % Save to disk
    waitbar(0.7, wb, 'Writing images...');
    metadata = writeImages(img, metadata, subject, datadir, 1, p.Results.rgb);
    waitbar(0.9, wb, 'Exporting metadata...'); 
    exportMetadata(metadata, metafile);
    if p.Results.doAsc
        exportMetadataToAsc(metadata, subject, datadir);
    end
catch e
    delete(wb);
    warning(getReport(e));
    msgbox(getReport(e,'basic'),'An error has occurred');
end

waitbar(1, wb, 'Done');
delete(wb);

% Register
% regMetadata = metadata;
% regCh = find(ismember(metadata.channels, registrationChannel));
% regMetadata.channels = metadata.channels(regCh);
% regMetadata.position = metadata.position(regCh,:);
% transforms = registerSeries(img(:,:,regCh,:), regMetadata, rois);
