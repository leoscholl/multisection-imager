function [ims, flats] = batch_flat(ims, flats, background)

if nargin < 3
    background = [];
end

msg = '';

if nargin < 2 || isempty(flats)

    h = ones(10,10)/100;
    for c = 1:size(ims,3)

        fprintf(repmat('\b',1,length(msg)));
        msg = sprintf('generating flat-field image %d/%d', c, size(ims,3));
        fprintf(msg)

        downsampled = ims(1:20:end,1:20:end,c,:);
        uAll = mean(downsampled(:));
        uIms = mean(reshape(downsampled, ...
            size(downsampled,1)*size(downsampled,2), size(downsampled,4)));
        toFilter = find(abs(uIms - uAll) < uAll/3);
        
        filt = zeros(size(ims,1),size(ims,2), length(toFilter), 'uint16');

        for n = 1:length(toFilter)
            filt(:,:,n) = imfilter(ims(:,:,c,toFilter(n)),h);
        end

        flats(:,:,c) = uint16(median(filt,3));
    end
    filt = [];
    fprintf('\n');
end

msg = '';
for n = 1:size(ims,4)
    fprintf(repmat('\b',1,length(msg)));
    msg = sprintf('applying flat-field correction to img %d/%d', n, size(ims,4));
    fprintf(msg)
    ims(:,:,:,n) = flatfield(ims(:,:,:,n), flats, background);
end

fprintf('\n');