function imdata = blobDetect(proc, imdata, n, channel, reference)
% blobDetect
% 
% INPUTS: 
%   proc - image matrix
%   imdata - metadata
%   n - image number
%   channel - which channel to detect
%
% OUTPUTS:
%   imdata - metadata with blobs
%

% parameters
sigmaFg = 2/imdata.pixelSize; % 8 um
sigmaBg = 20/imdata.pixelSize;
minSize = round(pi*3^2/imdata.pixelSize^2); % 5-15 um radius
maxSize = round(pi*12^2/imdata.pixelSize^2);

% pad the image
r = ceil(4*sigmaBg);
edge = 4;
pad = padarray(double(proc(edge+1:end-edge,edge+1:end-edge,:,n)),...
    [r+edge r+edge],'symmetric');

% gaussian filter
f = imgaussfilt(pad, sigmaFg);

% subtract background
minusBg = f - imgaussfilt(f,sigmaBg);
for c = 1:size(minusBg,3)
    s = std2(minusBg(:,:,c));
    minusBg(:,:,c) = mat2gray(minusBg(:,:,c), [-3*s, 3*s]);
end

% find the candidate cells by thresholding
b = imbinarize(minusBg(r+1:end-r,r+1:end-r,channel),0.99);
b = imfill(b,'holes');
se = strel('disk', round(5/imdata.pixelSize));
b = imopen(b, se);
b = bwareafilt(b, [minSize maxSize]);

% make a mask over the candidate cells
mask = bwmorph(b, 'skel', Inf);
se = strel('disk', round(50/imdata.pixelSize),8);
mask = imdilate(mask, se);

% normalize the channel means around the masked areas
localContrast=sqrt(imgaussfilt(minusBg.^2,sigmaBg));
localNormalized=minusBg(r+1:end-r,r+1:end-r,:)./localContrast(r+1:end-r,r+1:end-r,:);
localNormalized(~mask) = NaN;

% subtract the reference from channel
sCh = nanstd(reshape(localNormalized(:,:,channel),size(proc,1)*size(proc,2),1));
thr = 2*sCh;
diff = localNormalized(:,:,channel) - localNormalized(:,:,reference);

% binarize the new image
b = and(imbinarize(diff, thr),b);
b = imfill(b,'holes');
se = strel('disk', round(5/imdata.pixelSize));
b = imopen(b, se);
b = bwareafilt(b, [minSize maxSize]);

% find regions
stats = regionprops(b, 'Centroid', 'Area');
imdata.blobs(n) = stats;
end
