function metadata = countCells(varargin)
% countCells
%
% img - 4d matrix of image tiles (OPTIONAL)
% metadata - image metadata
% channelPairs - n x 2 cell string of channel/reference pairs
% downsample - integer downsample factor
% circThr - circularity threshold (1 circular, 0 linear)

% Parse inputs
if isstruct(varargin{1})
    metadata = varargin{1};
    channelPairs = varargin{2};
    if nargin > 2
        downsample = varargin{3};
    end
    if nargin > 3
        circThr = varargin{4};
    end
else
    if nargin < 3
        error('Not enough input arguments');
    end
    img = varargin{1};
    metadata = varargin{2};
    channelPairs = varargin{3};
    if nargin > 3
        downsample = varargin{4};
    end
    if nargin > 4
        circThr = varargin{5};
    end
end

if ~exist('downsample', 'var')
    downsample = 2;
end
if ~exist('circThr', 'var')
    circThr = 0.5;
end

% Parse channel pairs
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

% Count each section
msg = '';
for n = 1:length(metadata.boundaries)
    
    fprintf(repmat('\b',1,length(msg)));
    msg = sprintf('finding cells in slice %d/%d', n, length(metadata.boundaries));
    fprintf(msg)
    
    % Prepare images
    if exist('img', 'var')
        [I,offset] = stitchImg(img, metadata, downsample, [], metadata.boundaries{n}, false);
    else
        clearvars I
        for c = 1:size(metadata.imagepath,2)
            I(:,:,c) = imread(metadata.imagepath{n,c});
        end
        I = I(1:downsample:end,1:downsample:end,:);
        offset = [0 0];
        if isfield(metadata, 'positions')
            [~, ~, ~, offset] = calculateBounds(metadata, [], metadata.boundaries{n}, false);
        end
    end
    
    % Get binary image of blobs
    b = binaryBlobs(I, metadata.pixelSize*downsample, pairs);
    for c = 1:size(b,3)
        stats = regionprops(b(:,:,c), 'Centroid', 'EquivDiameter', 'Perimeter', 'Area');
        
        % Remove blobs with circularity below threshold
        circularity = 4*pi*cell2mat({stats.Area}')./cell2mat({stats.Perimeter}').^2;
        circular = circularity >= circThr;
        stats(~circular) = [];
        circularity(~circular) = [];
        
        % Remove blobs outside the brain outline
        centroid = cell2mat({stats.Centroid}').*downsample;
        if ~isempty(centroid)
            centroid = centroid + offset;
            [in, on] = inpolygon(centroid(:,1), centroid(:,2), ...
                metadata.boundaries{n}(:,1), metadata.boundaries{n}(:,2));
            inBounds = in | on;
            stats(~inBounds) = [];
            centroid(~inBounds) = [];
            circularity(~inBounds) = [];
        end
        
        % Save information to metadata
        metadata.cells{n,c}.centroid = centroid;
        metadata.cells{n,c}.diameter = cell2mat({stats.EquivDiameter}').*downsample;
        metadata.cells{n,c}.circularity = circularity;
        metadata.cells{n,c}.channel = pairs(c,1);
    end
end
fprintf('\n');