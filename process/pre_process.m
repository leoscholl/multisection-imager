function proc = pre_process(ims)

% Normalize channels, convert to uint8
fprintf('normalizing channels...\n');
proc = zeros(size(ims),'uint8');
for c = 1:size(ims,3)
    downsampled = ims(1:20:end,1:20:end,c,:);
    lo = double(prctile(downsampled(:),0.1))/double(intmax('uint16'));
    hi = double(prctile(downsampled(:),99.9))/double(intmax('uint16'));
    
    for img = 1:size(ims,4)
        proc(:,:,c,img) = uint8(imadjust(ims(:,:,c,img), ...
            [lo hi], [0 255/double(intmax('uint16'))]));
    end
end
