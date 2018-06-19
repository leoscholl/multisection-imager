function metadata = segmentSlide(img, metadata, downsample, confirmation)
% segmentSlide determine ROIs automatically or with user confirmation

if ~exist('downsample', 'var') || isempty(downsample)
    downsample = round(sqrt(size(img,4))*5);
end
if ~exist('confirmation', 'var') || isempty(confirmation)
    confirmation = true;
end

% Create downsampled fusion
I = stitchImg(img, metadata, downsample, []);

% Filter and threshold
sigma = 400/downsample;
f = imgaussfilt(I(:,:,end), sigma);

[rois, sections, boundaries, refs] = slide_segmenter(I(:,:,end), f, confirmation);
metadata.sections = sections;
metadata.rois = rois.*downsample;
metadata.boundaries = cellfun(@(x)fliplr(x).*downsample,boundaries,'UniformOutput',false);
metadata.refs = refs.*downsample;

end