function metadata = countCellsExisting(rootdir, subject, sections, channelPairs)

if ~exist('channelPairs', 'var') || isempty(channelPairs)
    channelPairs = {'mCherry', 'GFP'}; % 'GFP', 'mCherry'; 'BFP', 'GFP'};
end
if ~exist('sections', 'var')
    sections = [];
end
if ~exist('downsample', 'var')
    downsample = 2;
end

% find files
files = dir(fullfile(rootdir, subject, '*', '*.jp2'));
files = [files dir(fullfile(rootdir, subject, '*', '*.tiff'))];
sect = arrayfun(@(x)regexpi(x.name, 'sect(?:ion)?\s?(\d{1,3})', 'tokens'), ...
    files, 'UniformOutput', false);
valid = cellfun(@(x)~isempty(x)&&~isnan(str2double(x{1})), sect);
sect = cellfun(@(x)str2double(x{1}), sect(valid));
files = files(valid);
if isempty(sections)
    sections = unique(sect);
end
metadata.sections = sections;

msg = '';
for n = 1:length(sections)

    fprintf(repmat('\b',1,length(msg)));
    msg = sprintf('finding cells in slice %d/%d', n, length(sections));
    fprintf(msg)
    
    sectFiles = files(ismember(sect, sections(n)));
    
    % create basic metadata
    metadata.pixelSize = 1.306; % ?????????? who knows
    metadata.channels = {};
    for c = 1:length(sectFiles)
        ch = regexpi(sectFiles(c).name, '[-_\s]([a-zA-Z]{3,10})\.', 'tokens');
        metadata.channels{c} = ch{1}{1};
    end
    
    % load images
    img = [];
    pairs = [];
    i = 1;
    for p = 1:size(channelPairs,1)
        p1 = find(ismember(metadata.channels, channelPairs{p,1}));
        p2 = find(ismember(metadata.channels, channelPairs{p,2}));
        if ~isempty(p1) && ~isempty(p2)
            pairs(i,:) = [p1 p2];
            i = i + 1;
        end
    end
    channels = unique(pairs);
    for c = 1:length(channels)
        filepath = fullfile(sectFiles(channels(c)).folder, sectFiles(channels(c)).name);
        img(:,:,channels(c)) = imread(filepath);
    end
    metadata.width = size(img, 2);
    metadata.height = size(img, 1);
    img = img(1:downsample:end,1:downsample:end,:);
    
    b = blobDetect(img, metadata.pixelSize*downsample, pairs);
    for c = 1:size(b,3)
        stats = regionprops(b(:,:,c), 'Centroid');
        metadata.cells{n,c}.channel = pairs(c,1);
        metadata.cells{n,c}.centroid = cell2mat(struct2cell(stats)')*downsample;
    end
end

% exportMetadataToAsc(metadata, subject, datadir);
fprintf('\n');