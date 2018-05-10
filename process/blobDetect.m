function b = blobDetect(img, pixelSize, pairs)
% blobDetect
% 
% INPUTS: 
%   img - image matrix
%   pixelSize - metadata
%   pairs - which channels to detect and which to reference
%
% OUTPUTS:
%   b - binary image with blobs = 1
%

% parameters
sigmaFg = 2/pixelSize; % 2 um
sigmaBg = 30/pixelSize;
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
    f(:,:,c) = mat2gray(f(:,:,c), [m-3*s, m+3*s]);
end

% normalize local contrast
localContrast=sqrt(imgaussfilt(f.^2,sigmaBg));
localNormalized=single(f./localContrast);

localContrast = [];

b = zeros(size(img, 1), size(img, 2), size(pairs, 1), 'logical');
for p = 1:size(pairs, 1)

    channel = pairs(p,1);
    reference = pairs(p,2);
    
    % find the candidate cells by thresholding the filtered difference
    diff = f(:,:,channel) - f(:,:,reference);
    b1 = imbinarize(diff,0.9-0.5);
    b1 = imfill(b1,'holes');
    se = strel('disk', round(5/pixelSize));
    b1 = imclose(b1, se);
    b1 = bwareafilt(b1, [minSize maxSize]);

    % make a mask over the candidate cells
    mask = bwmorph(b1, 'skel', Inf);
    se = strel('disk', round(50/pixelSize),8);
    mask = imdilate(mask, se);

    % normalize the channel means around the masked areas
    localNormalized2 = localNormalized;
    localNormalized2(~mask) = NaN;

    % subtract the reference from channel
    sCh = nanstd(single(reshape(localNormalized2(:,:,channel),size(img,1)*size(img,2),1)));
    thr = 2*sCh;
    diff = localNormalized2(:,:,channel) - localNormalized2(:,:,reference);

    % binarize the new image
    b2 = and(imbinarize(diff, thr), b1);
    b2 = imfill(b2,'holes');
    se = strel('disk', round(5/pixelSize));
    b2 = imclose(b2, se);
    b2 = bwareafilt(b2, [minSize maxSize]);

    b(:,:,p) = b2;
    
end
