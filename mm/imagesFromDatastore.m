function [img, metadata] = imagesFromDatastore(store, datatype)
% Collect images from a micromanager datastore

if ~exist('datatype', 'var') || isempty(datatype)
    datatype = 'uint16';
end

% Initialize image matrix
Image = store.getAnyImage();
Meta = Image.getMetadata();
height = Image.getHeight();
width = Image.getWidth();
scopeData = Meta.getScopeData();
if scopeData.containsKey('pco_camera-CameraType') && ...
    strcmp(scopeData.getString('pco_camera-CameraType'), 'SensiCam')
    bitDepthImage = 12;
else
    bitDepthImage = 2^(Image.getBytesPerPixel()*8);
end
bitDepthStorage = log2(double(intmax(datatype))-double(intmin(datatype))+1);
axes = cellstr(char(store.getAxes().toArray()));
lengths = cellfun(@(x)double(store.getAxisLength(x)), axes);
lengths = reshape(lengths, 1, length(lengths));
img = zeros([height, width, lengths], datatype);

iter = store.getUnorderedImageCoords().iterator;
msg = '';

% Load metadata and images one at a time
i = 1;
while(iter.hasNext)
    
    if mod(i,10) == 1 || i == prod(lengths)
        fprintf(repmat('\b',1,length(msg)));
        msg = sprintf('loading image %d/%d', i, prod(lengths));
        fprintf(msg)
    end
    i = i + 1;
    
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
    plane = reshape(Image.getRawPixels, width, height)';
    if (bitDepthStorage < bitDepthImage)
        plane = plane * (2^bitDepthStorage/2^bitDepthImage);
    end
    img(:,:,Coords.getChannel()+1,Coords.getStagePosition()+1,...
        Coords.getZ()+1, Coords.getTime()+1) = plane;
end
metadata.position = position;
metadata.height = height;
metadata.width = width;
metadata.filepath = char(store.getSavePath());

fprintf('\n');
