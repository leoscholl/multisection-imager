function flats = generateFlats(img, metadata)
% generateFlats Use images

% Automatic segmentation to find images with brain tissue only
if ~isfield(metadata, 'boundaries') || isempty(metadata.boundaries)
    metadata = segmentSlide(img, metadata, [], false);
end
toFilter = zeros(1,size(img,4));
for n = 1:length(metadata.boundaries)
    [~, ~, inBounds] = calculateBounds(metadata, [], metadata.boundaries{n},true);
    toFilter = toFilter | inBounds;
end
if sum(toFilter) < 100
    warning('Too few images to generate good flat-field');
end

% Median Z-projected flat field from gaussian filtered images
msg = '';
h = ones(10,10)/100;
flats = zeros(size(img,1),size(img,2),size(img,3),'like',img);
for c = 1:size(img,3)
    
    fprintf(repmat('\b',1,length(msg)));
    msg = sprintf('generating flat-field image %d/%d', c, size(img,3));
    fprintf(msg)
    
    filt = imfilter(img(:,:,c,toFilter),h);    
    flats(:,:,c) = median(filt,4);
end
fprintf('\n');

end