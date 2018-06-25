function metadata = countCells(img, metadata, channelPairs, downsample)
% countCells

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

msg = '';
for n = 1:size(metadata.boundaries,1)
    
    fprintf(repmat('\b',1,length(msg)));
    msg = sprintf('finding cells in slice %d/%d', n, size(metadata.boundaries,1));
    fprintf(msg)
    
    [I,offset] = stitchImg(img, metadata, downsample, [], metadata.boundaries{n}, false);
    b = blobDetect(I, metadata.pixelSize*downsample, pairs);
    for c = 1:size(b,3)
        stats = regionprops(b(:,:,c), 'Centroid');
        metadata.cells{n,c}.channel = pairs(c,1);
        centroid = cell2mat(struct2cell(stats)').*downsample;
        if ~isempty(centroid)
            centroid = centroid + offset;
        end
        metadata.cells{n,c}.centroid = centroid;
    end
end
fprintf('\n');