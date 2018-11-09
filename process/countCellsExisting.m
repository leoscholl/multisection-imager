function metadata = countCellsExisting(metadata, channelPairs, downsample)

if ~exist('channelPairs', 'var') || isempty(channelPairs)
    channelPairs = {'mCherry', 'GFP'}; % 'GFP', 'mCherry'; 'BFP', 'GFP'};
end
if ~exist('downsample', 'var')
    downsample = 2;
end

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

% find files
msg = '';
for n = 1:length(metadata.sections)

    fprintf(repmat('\b',1,length(msg)));
    msg = sprintf('finding cells in slice %d/%d', n, length(metadata.sections));
    fprintf(msg)
    
    % load images
    clearvars img
    for c = 1:size(metadata.imagepath,2)
        img(:,:,c) = imread(metadata.imagepath{n,c});
    end
    img = img(1:downsample:end,1:downsample:end,:);
    
    b = blobDetect(img, metadata.pixelSize*downsample, pairs);
    [~, ~, ~, offset] = calculateBounds(metadata, [], metadata.boundaries{n}, false);
    for c = 1:size(b,3)
        stats = regionprops(b(:,:,c), 'Centroid', 'EquivDiameter');
        metadata.cells{n,c}.channel = pairs(c,1);
        centroid = cell2mat({stats.Centroid}').*downsample;
        metadata.cells{n,c}.diameter = cell2mat({stats.EquivDiameter}').*downsample;
        if ~isempty(centroid)
            % Remove any cells outside the brain outline
            centroid = centroid + offset;
            [in, on] = inpolygon(centroid(:,1), centroid(:,2), ...
                metadata.boundaries{n}(:,1), metadata.boundaries{n}(:,2));
            centroid(~in & ~on,:) = [];
        end
        metadata.cells{n,c}.centroid = centroid;
    end
end
fprintf('\n');