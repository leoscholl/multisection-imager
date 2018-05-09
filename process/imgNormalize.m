function proc = imgNormalize(img, output)
% imgNormalize Clamp each channel to 0.1 through 99.9th percentile

if ~exist('output', 'var') || isempty(output)
    output = 'uint8';
end
outputFun = str2func(output);
input = class(img);

% Normalize channels, convert to uint8
msg = '';
proc = zeros(size(img),output);
for c = 1:size(img,3)
    fprintf(repmat('\b',1,length(msg)));
    msg = sprintf('normalizing channel %d/%d', c, size(img,3));
    fprintf(msg);
    downsampled = double(img(1:20:end,1:20:end,c,:));
    lo = double(prctile(downsampled(:),0.1))/double(intmax(input));
    hi = double(prctile(downsampled(:),99.9))/double(intmax(input));
    
    for i = 1:size(img,4)
        proc(:,:,c,i) = outputFun(imadjust(img(:,:,c,i), ...
            [lo hi], [0 double(intmax(output))/double(intmax(input))]));
    end
end
fprintf('\n');