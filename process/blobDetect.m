function b = blobDetect(img, pixelSize, pairs, tolerance)
% blobDetect
% 
% INPUTS: 
%   img - image matrix
%   pixelSize - metadata
%   pairs - which channels to detect and which to reference
%   tolerance - how lenient to be (0 to 1)
%
% OUTPUTS:
%   b - binary image with blobs = 1
%

if ~exist('tolerance', 'var') || isempty(tolerance)
    tolerance = 0.55;
end

% parameters
sigmaFg = 5/pixelSize; % bandpass with 5-40 um sigma DoG
sigmaBg = 40/pixelSize; 
sigmaLc = 40/pixelSize; % to determine local contrast
minSize = round(pi*5^2/pixelSize^2); % 5-12 um radius
maxSize = round(pi*12^2/pixelSize^2);

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
    f(:,:,c) = mat2gray(f(:,:,c), [m-6*s, m+6*s]);
end
f = single(f);

% normalize local contrast
localContrast=sqrt(imgaussfilt(f.^2,sigmaLc));
localNormalized=f./localContrast;
localContrast = [];

b = zeros(size(img, 1), size(img, 2), size(pairs, 1), 'logical');
for p = 1:size(pairs, 1)

    channel = pairs(p,1);
    reference = pairs(p,2);
    
    % find the candidate cells by simple thresholding of the filtered image
    b1 = imbinarize(f(:,:,channel), 0.99);
    b1 = imfill(b1,'holes');
    se = strel('disk', round(5/pixelSize));
    b1 = imclose(b1, se);
    b1 = bwareafilt(b1, [minSize maxSize]);

    % subtract the reference from channel
    diff = localNormalized(:,:,channel) - localNormalized(:,:,reference);

    % binarize the new image; and with candidate cells
    b2 = and(imbinarize(diff, 1-tolerance), b1);
    b2 = imfill(b2,'holes');
    se = strel('disk', round(5/pixelSize));
    b2 = imclose(b2, se);
    b2 = bwareafilt(b2, [minSize maxSize]);

    b(:,:,p) = b2;
    
end
