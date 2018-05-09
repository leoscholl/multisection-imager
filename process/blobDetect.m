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

% gaussian filter
f = imgaussfilt(double(img), sigmaFg);

% subtract background
minusBg = f - imgaussfilt(f,sigmaBg);
f = [];
for c = 1:size(minusBg,3)
    s = std2(minusBg(:,:,c));
    minusBg(:,:,c) = mat2gray(minusBg(:,:,c), [-3*s, 3*s]);
end

% normalize local contrast
localContrast=sqrt(imgaussfilt(minusBg.^2,sigmaBg));
localNormalized=single(minusBg./localContrast);

localContrast = [];

b = zeros(size(img, 1), size(img, 2), size(pairs, 1), 'logical');
for p = 1:size(pairs, 1)

    channel = pairs(p,1);
    reference = pairs(p,2);
    
    % find the candidate cells by thresholding
    b1 = imbinarize(minusBg(:,:,channel),0.99);
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
