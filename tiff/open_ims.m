function [ims, omeMeta] = open_ims(tiff)
% Load images
msg = '';
fprintf('reading images...\n');
reader = bfGetReader(tiff);
omeMeta = reader.getMetadataStore();
nImages = omeMeta.getImageCount();
nChannels = reader.getImageCount();

ims = zeros(reader.getSizeY(), reader.getSizeX(), ...
    nChannels, nImages, 'uint16');

for n = 1:nImages
    
    fprintf(repmat('\b',1,length(msg)));
    msg = sprintf('reading img %d/%d', n, nImages);
    fprintf(msg)
    reader.setSeries(n-1);
    for c = 1:nChannels
        ims(:,:,c,n) = bfGetPlane(reader, c);
    end
    
end
reader.close();
fprintf('\n');
end

