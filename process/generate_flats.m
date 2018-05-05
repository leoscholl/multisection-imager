function flats = generate_flats(img, metadata)

msg = '';
h = ones(10,10)/100;
for c = 1:size(img,3)
    
    fprintf(repmat('\b',1,length(msg)));
    msg = sprintf('generating flat-field image %d/%d', c, size(img,3));
    fprintf(msg)
    
    % Automatic segmentation to find images with brain tissue only
    downsample = 20;
    rois = segmentSlide(img, metadata, downsample, false);
    toFilter = [];
    for n = 1:size(rois,1)
        [~, ~, inBounds, ~] = calculateBounds(metadata, rois(n,:));
        toFilter = union(toFilter, inBounds);
    end
    
    filt = zeros(size(img,1),size(img,2), length(toFilter), 'uint16');
    
    for n = 1:length(toFilter)
        filt(:,:,n) = imfilter(img(:,:,c,toFilter(n)),h);
    end
    
    flats(:,:,c) = uint16(median(filt,3));
end
fprintf('\n');
end