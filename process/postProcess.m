function postProcess(store, datadir, subject, makeFlats, defaultFlats, ...
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
flats = zeros(size(img,1),size(img,2),size(img,3),'like',img);
if ~exist('makeFlats', 'var') || isempty(makeFlats)
    % by default only if image is large
    makeFlats = ~isfield(metadata, 'flats') && size(img,4) > 500; 
end
try
    m = load(defaultFlats);
    for c = 1:size(img,3)
        channelName = metadata.channels{c};
        flats(:,:,c) = m.flatfields.(channelName);
    end
    background = m.background;
catch e
    makeFlats = true;
end
if makeFlats
    flats = generateFlats(img, metadata);
end
metadata.flats = flats;
metadata.background = background;
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
exportMetadata(metadata, subject, datadir);
if doAsc
    exportMetadataToAsc(metadata, subject, datadir);
end

% Register
% regMetadata = metadata;
% regCh = find(ismember(metadata.channels, registrationChannel));
% regMetadata.channels = metadata.channels(regCh);
% regMetadata.position = metadata.position(regCh,:);
% transforms = registerSeries(img(:,:,regCh,:), regMetadata, rois);
