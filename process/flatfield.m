function im = flatfield(im, flat, background)

meanflat = zeros(1,1,size(flat,3));
for c = 1:size(flat,3)
    flatc = reshape(flat(:,:,c), 1, size(flat,1)*size(flat,2));
    meanflat(:,:,c) = mean(flatc);
end

if nargin < 3 || isempty(background)
    im = uint16(double(im) ./ double(flat) .* meanflat);
else
    im = uint16(double(im - background) ./ double(flat - background) ...
        .* meanflat);
end