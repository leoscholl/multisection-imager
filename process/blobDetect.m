function b = blobDetect(img, pixelSize, pairs, threshold)
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

if ~exist('threshold', 'var') || isempty(threshold)
    threshold = 0.75;
end

% parameters
sigmaFg = 5/pixelSize; % bandpass with 5-40 um sigma DoG
sigmaBg = 40/pixelSize; 
sigmaLc = 40/pixelSize; % to determine local contrast
minArea = round(pi*3^2/pixelSize^2); % 3-20 um radius
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
    f(:,:,c) = mat2gray(f(:,:,c), [m-5*s, m+5*s]); % scale into range 0-1
end
f = single(f);

% normalize local contrast
localContrast=sqrt(imgaussfilt(f.^2,sigmaLc));
localNormalized=f./localContrast; % anything below 1 is dark
localNormalized=single(mat2gray(localNormalized, [1 3]));
localContrast = [];

b = zeros(size(img, 1), size(img, 2), size(pairs, 1), 'logical');
for p = 1:size(pairs, 1)

    channel = pairs(p,1);
    reference = pairs(p,2);
    
    % find the candidate cells by simple thresholding of the filtered image
    candidates = imbinarize(f(:,:,channel), 0.99);

    % find dirt/dust with thresholded reference image
    dust = imbinarize(f(:,:,reference), 0.99);
    se = strel('disk', round(40/pixelSize)); % enlarge to 40um radius
    dust = imdilate(dust, se);
    
    % use the local contrast to find autofluorescence
    autofluoro = and(imbinarize(localNormalized(:,:,reference)), ...
        imbinarize(localNormalized(:,:,channel)));
    autofluoro = imdilate(autofluoro, se);
    
    % combine and filter based on area
    b2 = and(and(candidates, not(autofluoro)), not(dust));
    se = strel('disk', round(5/pixelSize));
    b2 = imclose(b2, se);
    b2 = bwareafilt(b2, [minArea maxArea]);
    
% 
%     % find the candidate cells by simple thresholding of the filtered image
%     candidates = imbinarize(f(:,:,channel), 0.99);
%     candidates = bwareafilt(candidates, [minArea maxArea]);
%     
%     % find dirt/dust with thresholded reference image
%     dust = imbinarize(f(:,:,reference), 0.99);
%     se = strel('disk', round(40/pixelSize)); % enlarge to 40um radius
%     dust = imdilate(dust, se);
%     b2 = and(candidates, not(dust));
% 
%     % use the difference of local contrasts to remove autofluorescence
%     diff = localNormalized(:,:,channel) - localNormalized(:,:,reference);
%     diff = imbinarize(diff, 1-tolerance);
%     b2 = and(diff, b2);
%     se = strel('disk', round(5/pixelSize));
%     b2 = imclose(b2, se);
%     b2 = bwareafilt(b2, [minArea maxArea]); % remove small spots

    b(:,:,p) = b2;
    
end
