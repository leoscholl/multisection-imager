function proc = imgNormalize(img, metadata, output, bottom, top)
% imgNormalize Clamp each channel from bottom to top'th percentile

if ~exist('output', 'var') || isempty(output)
    output = 'uint8';
end
outputFun = str2func(output);
input = class(img);

if ~exist('bottom', 'var') || isempty(bottom)
    bottom = 5;
end
if ~exist('top', 'var') || isempty(top)
    top = 99.9;
end

% Determine foreground images
if ~isfield(metadata, 'rois') || isempty(metadata.rois)
    metadata = segmentSlide(img, metadata, [], false);
end
foreground = zeros(1,size(img,4));
for n = 1:length(metadata.rois)
    [~, ~, inBounds] = calculateBounds(metadata, metadata.rois(n,:));
    foreground = foreground | inBounds;
end

% Normalize channels, convert to uint8
msg = '';
proc = zeros(size(img),output);
for c = 1:size(img,3)
    fprintf(repmat('\b',1,length(msg)));
    msg = sprintf('normalizing channel %d/%d', c, size(img,3));
    fprintf(msg);
    downsampled = double(img(1:20:end,1:20:end,c,foreground));
    lo = double(prctile(downsampled(:),bottom))/double(intmax(input));
    hi = double(prctile(downsampled(:),top))/double(intmax(input));
    
    for i = 1:size(img,4)
        proc(:,:,c,i) = outputFun(imadjust(img(:,:,c,i), ...
            [lo hi], [0 double(intmax(output))/double(intmax(input))]));
    end
end
fprintf('\n');