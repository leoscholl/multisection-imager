function proc = imgNormalize(img, n, output)
% imgNormalize Clamp each channel +/- n standard deviations from the mean

if ~exist('n', 'var') || isempty(n)
    n = 4;
end
if ~exist('output', 'var') || isempty(output)
    output = 'uint8';
end
outputFun = str2func(output);

% Normalize channels, convert to uint8
msg = '';
proc = zeros(size(img),'uint8');
for c = 1:size(img,3)
    fprintf(repmat('\b',1,length(msg)));
    msg = sprintf('normalizing channel %d/%d', c, size(img,3));
    fprintf(msg);
    downsampled = double(img(1:20:end,1:20:end,c,:));
    m = mean(downsampled(:));
    s = std(downsampled(:));
    lo = (m + n*s)/double(intmax('uint16'));
    hi = (m - n*s)/double(intmax('uint16'));
    
    for img = 1:size(img,4)
        proc(:,:,c,img) = outputFun(imadjust(img(:,:,c,img), ...
            [lo hi], [0 double(intmax(output))/double(intmax('uint16'))]));
    end
end
fprintf('\n');