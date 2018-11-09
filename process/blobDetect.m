function b = blobDetect(img, pixelSize, pairs, sigma)
% blobDetect
% 
% INPUTS: 
%   img - image matrix
%   pixelSize - metadata
%   pairs - which channels to detect and which to reference
%   threshold - for finding cells
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
% h = fspecial('gaussian', round(sigmaBg*3)*2+1, sigmaFg) - ...
%     fspecial('gaussian', round(sigmaBg*3)*2+1, sigmaBg);
% f = imfilter(double(img), h);
f = imgaussfilt(double(img), sigmaFg); % seems faster
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

    % exclude sharp edges
    edges = edge(f(:,:,reference), 'canny', [0.05, 0.2]);
    edges = bwareaopen(edges, minArea);
    edges = imdilate(edges,strel('disk',round(12/pixelSize)));
    edges = imfill(edges, 'holes');
    
    % combine and filter based on area
    b2 = and(candidates, not(edges));
    b2 = bwareafilt(b2, [minArea maxArea]);
    
    b(:,:,p) = b2;
    
end
