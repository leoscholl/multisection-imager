function b = binaryBlobs(img, pixelSize, pairs, sigma)
% blobDetect
% 
% INPUTS: 
%   img - image matrix
%   pixelSize - metadata
%   pairs - which channels to detect and which to reference
%   sigma - threshold above the mean
%
% OUTPUTS:
%   b - binary image with blobs = 1
%

if ~exist('sigma', 'var') || isempty(sigma)
    sigma = 4;
end

if sigma < 0
    error('Sigma must be above 0');
end

% parameters
sigmaFg = 5/pixelSize; % bandpass with 5-30 um sigma DoG
sigmaBg = 30/pixelSize; 
sigmaLc = 100/pixelSize; % to determine local contrast
minArea = round(pi*4^2/pixelSize^2); % 4-20 um radius
maxArea = round(pi*20^2/pixelSize^2);

% difference of gaussian filter
f = imgaussfilt(double(img), sigmaFg);
f = f - imgaussfilt(f,sigmaBg);

% normalize
for c = 1:size(f,3)
    s = std2(f(:,:,c));
    m = mean2(f(:,:,c));
    f(:,:,c) = mat2gray(f(:,:,c), [m-6*s, m+6*s]); % scale into range 0-1
end

% normalize local contrast
localContrast=sqrt(imgaussfilt(f.^2,sigmaLc));
localNormalized=f./localContrast;

b = zeros(size(img, 1), size(img, 2), size(pairs, 1), 'logical');
for p = 1:size(pairs, 1)

    channel = pairs(p,1);
    reference = pairs(p,2);
    
    % find the candidate cells
    sub = localNormalized(:,:,channel) - localNormalized(:,:,reference);
    candidates = imbinarize(sub, sigma/6); % 1 is 6 std above mean
    candidates = imclose(candidates, strel('disk', round(4/pixelSize)));
    candidates = bwareafilt(candidates, [minArea maxArea]);

    % find sharp edges
    edges = edge(f(:,:,reference).*f(:,:,channel), 'canny', [0.1, 0.2]);
    edges = bwareaopen(edges, minArea);
    edges = imdilate(edges,strel('disk',round(12/pixelSize)));
    edges = imfill(edges, 'holes');

    % exclude candidates that overlap any edge
    b2 = zeros(1,size(candidates,1)*size(candidates,2),'like',candidates);
    CC = bwconncomp(candidates, 4);
    le = edges(:);
    for i = 1:CC.NumObjects
        if all(le(CC.PixelIdxList{i})) == 0
            b2(CC.PixelIdxList{i}) = 1;
        end
    end
    b2 = reshape(b2, size(candidates));
    b2 = imfill(b2, 'holes');
    
    b(:,:,p) = b2;
    
end
