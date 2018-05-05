function [img, flats] = batch_flat(img, flats, background)

if nargin < 3
    background = [];
end

msg = '';
for n = 1:size(img,4)
    fprintf(repmat('\b',1,length(msg)));
    msg = sprintf('applying flat-field correction to img %d/%d', n, size(img,4));
    fprintf(msg)
    img(:,:,:,n) = flatfield(img(:,:,:,n), flats, background);
end

fprintf('\n');