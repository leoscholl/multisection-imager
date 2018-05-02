function [img, metadata] = imagesFromDatastore(store, Coords)
% Collect images from a micromanager datastore

Images = store.getImagesMatching(Coords).toArray();

% Parse metadata
metadata = [];
summary = store.getSummaryMetadata();
metadata.channels = char(summary.getChannelNames());

for l = 1:length(Images)
    Coords = Images(l).getCoords();
    Meta = Images(l).getMetadata();
    
    data = struct;
    data.x{l} = double(Meta.getXPositionUm().value);
    data.y{l} = double(Meta.getYPositionUm().value);
    data.z{l} = double(Meta.getZPositionUm().value);
    data.exposure{l} = double(Meta.getExposureMs());
    c = double(Coords.getChannel()+1);
    z = double(Coords.getZ()+1);
    t = double(Coords.getTime()+1);
    position(c,z,t) = data;
    
    metadata.pixelSize = double(Meta.getPixelSizeUm().value);
    height = Images(l).getHeight();
    width = Images(l).getWidth();
    bitDepth = Images(l).getBytesPerPixel();
    
end
metadata.pos = pos;

% Load pixel data
img = zeros(height, width, size(pos,2), size(pos,1), ...
    sprintf('uint%d', bitDepth*8));
for l = 1:length(Images)
    Coords = Images(l).getCoords();
    img(:,:,Coords.getStagePosition()+1,Coords.getChannel()+1,...
        Coords.getZ()+1, Coords.getTime()+1) = ...
        reshape(Images(l).getRawPixels, width, height)';
end
