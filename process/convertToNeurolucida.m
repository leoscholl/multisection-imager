function convertToNeurolucida(store, datadir, subject, sections, makeFlats, ...
    doCellCount, cellCountChannelPairs)

if ~exist('makeFlats', 'var') || isempty(makeFlats)
    makeFlats = true;
end
if ~exist('doCellCount', 'var') || isempty(doCellCount)
    doCellCount = false;
end
if ~exist('cellCountChannelPairs', 'var') || isempty(cellCountChannelPairs)
    cellCountChannelPairs = {'mCherry', 'GFP'}; % 'GFP', 'mCherry'; 'BFP', 'GFP'};
end

[img, metadata] = imagesFromDatastore(store);

% Flat field
background = [];
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
    flats = generate_flats(img, metadata);
    save('flatfields-temp.mat', 'flats');
end
img = batch_flat(img, flats, background);

% Normalize and downsample
img = pre_process(img);

% Segment
rois = segmentSlide(img, metadata);

% Find blobs and write neurolucida file
if doCellCount
    pairs = [];
    clearvars channels position
    i = 1;
    for p = 1:size(cellCountChannelPairs,1)
        p1 = find(ismember(metadata.channels, cellCountChannelPairs{p,1}));
        p2 = find(ismember(metadata.channels, cellCountChannelPairs{p,2}));
        if ~isempty(p1) && ~isempty(p2)
            pairs(i,:) = [p1 p2];
            channels{i} = metadata.channels{p1};
            position(i,:) = metadata.position(p1,:);
            i = i + 1;
        end
    end
    cellMetadata = metadata; cellMetadata.channels = channels; cellMetadata.position = position;
    bimg = find_blobs(img, metadata, pairs);
    
    % Save to disk
    exportToAsc(bimg, metadata, cellMetadata, rois, subject, datadir, sections);
else
    exportToAsc([], metadata, [], rois, subject, datadir, sections);
end

% Save images
writeImages(img, metadata, rois, subject, datadir, sections);

end

