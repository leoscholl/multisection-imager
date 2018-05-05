subject = 'LSR1801';
datadir = 'F:\Leo';
sections = ;

makeFlats = true;
registrationChannel = 'BFP';
cellCountChannelPairs = {'mCherry', 'GFP'}; % 'GFP', 'mCherry'; 'BFP', 'GFP'};

store = mm.displays().getCurrentWindow().getDatastore();

[img, metadata] = imagesFromDatastore(store);

% Flat field
background = [];
if ~makeFlats
    try
        m = load('F:\Leo\Background\flatfields.mat');
        for c = 1:size(img,3)
            channelName = imdata.channels{c};
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

% Find blobs
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

% Segment
rois = segmentSlide(img, metadata);

% Register
% regMetadata = metadata;
% regCh = find(ismember(metadata.channels, registrationChannel));
% regMetadata.channels = metadata.channels(regCh);
% regMetadata.position = metadata.position(regCh,:);
% transforms = registerSeries(img(:,:,regCh,:), regMetadata, rois);

% Save to disk
writeImages(img, metadata, rois, subject, datadir, sections);
% writeImages(bimg, cellMetadata, rois, subject, datadir, sections, 'cells');
exportCellsToAsc(bimg, metadata, cellMetadata, rois, subject, datadir, sections);