function [img, metadata] = imagesFromDatastore(store)
% Collect images from a micromanager datastore

% Initialize image matrix
Image = store.getAnyImage();
height = Image.getHeight();
width = Image.getWidth();
bitDepth = Image.getBytesPerPixel();
axes = cellstr(char(store.getAxes().toArray()));
lengths = cellfun(@(x)double(store.getAxisLength(x)), axes);
lengths = reshape(lengths, 1, length(lengths));
img = zeros([height, width, lengths], sprintf('uint%d', bitDepth*8));

iter = store.getUnorderedImageCoords().iterator;
msg = '';

% Load metadata and images one at a time
i = 1;
while(iter.hasNext)
    
    fprintf(repmat('\b',1,length(msg)));
    msg = sprintf('loading image %d/%d', i, prod(lengths));
    i = i + 1;
    fprintf(msg)
    
    Coords = iter.next;
    Image = store.getImage(Coords);
    Meta = Image.getMetadata();
    
    data = struct;
    data.x = double(Meta.getXPositionUm());
    data.y = double(Meta.getYPositionUm());
    data.z = double(Meta.getZPositionUm());
    c = double(Coords.getChannel()+1);
    p = double(Coords.getStagePosition()+1);
    z = double(Coords.getZ()+1);
    t = double(Coords.getTime()+1);
    
    metadata.pixelSize = double(Meta.getPixelSizeUm());
    metadata.channels{c} = '';
    data.exposure = [];
    
    % Some information is not present in normal metadata
    scopeData = Meta.getScopeData();
    if scopeData.containsKey('ZeissReflectorTurret-Label')
        metadata.channels{c} = char(scopeData.getString('ZeissReflectorTurret-Label'));
    end
    if scopeData.containsKey('pco_camera-Exposure')
        data.exposure = str2double(char(scopeData.getString('pco_camera-Exposure')));
    end
    
    position(c,p,z,t) = data;
    
    % finally, store the image
    img(:,:,Coords.getChannel()+1,Coords.getStagePosition()+1,...
        Coords.getZ()+1, Coords.getTime()+1) = ...
        reshape(Image.getRawPixels, width, height)';
end
metadata.position = position;
metadata.height = height;
metadata.width = width;
metadata.filepath = char(store.getSavePath());

fprintf('\n');
