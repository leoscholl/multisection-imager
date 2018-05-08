function postProcess(store, datadir, subject, sections, makeFlats, ...
    doAsc, doCellCount, cellCountChannelPairs)

if ~exist('makeFlats', 'var') || isempty(makeFlats)
    makeFlats = false;
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
    flats = generateFlats(img, metadata);
    save('flatfields-temp.mat', 'flats');
end
img = batchFlatfield(img, flats, background);

% Normalize and downsample
img = imgNormalize(img);

% Segment
metadata = segmentSlide(img, metadata);

% Find blobs
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
    cellMetadata = metadata; 
    cellMetadata.channels = channels; 
    cellMetadata.position = position;
    bimg = batchBlobDetect(img, metadata, pairs);
end

% Save to disk
writeImages(img, metadata, subject, datadir, sections);
if doAsc
    if doCellCount
        exportToAsc(bimg, metadata, cellMetadata, subject, datadir, sections);
    else
        exportToAsc([], metadata, [], subject, datadir, sections);
    end
elseif doCellCount
    writeImages(bimg, cellMetadata, subject, datadir, sections, 'cells');
end

end

% Register
% regMetadata = metadata;
% regCh = find(ismember(metadata.channels, registrationChannel));
% regMetadata.channels = metadata.channels(regCh);
% regMetadata.position = metadata.position(regCh,:);
% transforms = registerSeries(img(:,:,regCh,:), regMetadata, rois);
