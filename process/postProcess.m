function postProcess(store, datadir, subject, varargin)
% postProcess Make stitched images from the raw acquisition in store

p = inputParser();
p.addOptional('makeFlats', '');
p.addOptional('defaultFlats', '', @ischar);
p.addOptional('doAsc', false);
p.addOptional('doCellCount', false);
p.addOptional('cellCountChannelPairs', {'mCherry', 'GFP'});
p.addParameter('segmentOnly', false);
p.parse(varargin{:});

% Load images
if p.Results.segmentOnly; datatype = 'uint8';
else; datatype = 'uint16'; end
[img, metadata] = imagesFromDatastore(store, datatype);

% Load any existing metadata
[~, filename, ~] = fileparts(metadata.filepath);
metafile = fullfile(datadir, subject, filename, sprintf('%s.mat', filename));
if exist(metafile, 'file')
    load(metafile, 'metadata');
end

% Optionally just do segmentation and quit
if p.Results.segmentOnly
    metadata = segmentSlide(img, metadata);
    exportMetadata(metadata, subject, datadir);
    return
end

% Do a quick segmentation if there is none
if ~isfield(metadata, 'sections') || ~isfield(metadata, 'rois') || ...
        isempty(metadata.sections) || isempty(metadata.rois)
    roughMetadata = segmentSlide(img, metadata, [], false);
else
    roughMetadata = metadata;
end

% Flat field
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
if isempty(makeFlats) && ~isfield(metadata, 'flats')
    % by default only if image is large
    makeFlats = size(img,4) > 500; 
end
if makeFlats || isempty(flats)
    flats = generateFlats(img, roughMetadata);
end
metadata.flats = flats;
metadata.background = background;
img = batchFlatfield(img, flats, background);

% Normalize and downsample
img = imgNormalize(img, roughMetadata);

% Segment
if ~isfield(metadata, 'sections') || ~isfield(metadata, 'rois') || ...
        isempty(metadata.sections) || isempty(metadata.rois)
    metadata = segmentSlide(img, metadata);
end

% Find blobs
if p.Results.doAsc && p.Results.doCellCount
    metadata = countCells(img, metadata, p.Results.cellCountChannelPairs);
end

% Save to disk
metadata = writeImages(img, metadata, subject, datadir);
exportMetadata(metadata, subject, datadir);
if p.Results.doAsc
    exportMetadataToAsc(metadata, subject, datadir);
end

% Register
% regMetadata = metadata;
% regCh = find(ismember(metadata.channels, registrationChannel));
% regMetadata.channels = metadata.channels(regCh);
% regMetadata.position = metadata.position(regCh,:);
% transforms = registerSeries(img(:,:,regCh,:), regMetadata, rois);
