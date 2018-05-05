function bimg = find_blobs(img, imdata, pairs)

msg = '';
bimg = zeros(size(img,1), size(img, 2), size(pairs,1), size(img, 4), 'logical');
for i = 1:size(img, 4)
    
    fprintf(repmat('\b',1,length(msg)));
    msg = sprintf('finding blobs in image %d/%d', i, size(img,4));
    fprintf(msg)

    bimg(:,:,:,i) = blobDetect(img(:,:,:,i), imdata.pixelSize, pairs);
    
end

fprintf('\n');