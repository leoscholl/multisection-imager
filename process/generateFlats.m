function flats = generateFlats(img, metadata)
% generateFlats Use images 

msg = '';
h = ones(10,10)/100;
for c = 1:size(img,3)
    
    fprintf(repmat('\b',1,length(msg)));
    msg = sprintf('generating flat-field image %d/%d', c, size(img,3));
    fprintf(msg)
    
    % Automatic segmentation to find images with brain tissue only
    downsample = 50;
    metadata = segmentSlide(img, metadata, downsample, false);
    toFilter = [];
    for n = 1:length(metadata.hulls)
        [~, ~, inBounds] = calculateBounds(metadata, [], metadata.hulls{n},true);
        toFilter = union(toFilter, inBounds);
    end
    if length(toFilter) < 100
        warning('Too few images to generate good flat-field');
    end
    filt = zeros(size(img,1),size(img,2), length(toFilter), 'uint16');
    
    for n = 1:length(toFilter)
        filt(:,:,n) = imfilter(img(:,:,c,toFilter(n)),h);
    end
    
    flats(:,:,c) = uint16(median(filt,3));
end
fprintf('\n');
end