function postProcess(store, datadir, subject, makeFlats, ...
    doAsc, doCellCount, cellCountChannelPairs)
% postProcess Make stitched images from the raw acquisition in store

if ~exist('doCellCount', 'var') || isempty(doCellCount)
    doCellCount = false;
end
if ~exist('cellCountChannelPairs', 'var') || isempty(cellCountChannelPairs)
    cellCountChannelPairs = {'mCherry', 'GFP'}; % 'GFP', 'mCherry'; 'BFP', 'GFP'};
end

% Load images
[img, metadata] = imagesFromDatastore(store);

% Load any existing metadata
[~, filename, ~] = fileparts(metadata.filepath);
metafile = fullfile(metadata.filepath, strcat(filename, '.mat'));
if exist(metafile, 'file')
    load(metafile, 'metadata');
end


% Flat field
background = [];
if ~exist('makeFlats', 'var') || isempty(makeFlats)
    makeFlats = size(img,4) > 500; % by default only if image is large
end
if ~makeFlats
    try
        m = load('F:\Leo\Background\flatfields.mat');
        for c = 1:size(img,3)
            channelName = metadata.channels{c};
            flats(:,:,c) = m.flatfields.(channelName);
        end
        background = m.flatfields.background;
    catch e
        makeFlats = true;
    end
end
if makeFlats
    flats = generateFlats(img, metadata);
    save('F:\Leo\Background\flatfields-temp.mat', 'flats');
end
img = batchFlatfield(img, flats, background);

% Normalize and downsample
img = imgNormalize(img);

% Segment
if ~isfield(metadata, 'sections') || ~isfield(metadata, 'rois') || ...
        isempty(metadata.sections) || isempty(metadata.rois)
    metadata = segmentSlide(img, metadata);
end

% Find blobs
if doAsc && doCellCount
    metadata = countCells(img, metadata, cellCountChannelPairs);
end

% Save to disk
metadata = writeImages(img, metadata, subject, datadir);
if doAsc
    exportMetadataToAsc(metadata, subject, datadir);
end
if doCellCount
    exportMetadata(metadata, subject, datadir);
end
end

% Register
% regMetadata = metadata;
% regCh = find(ismember(metadata.channels, registrationChannel));
% regMetadata.channels = metadata.channels(regCh);
% regMetadata.position = metadata.position(regCh,:);
% transforms = registerSeries(img(:,:,regCh,:), regMetadata, rois);
