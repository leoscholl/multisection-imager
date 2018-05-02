function [img, metadata] = imagesFromMM(store)
% Collect images from a micromanager datastore

import org.micromanager.data.internal.DefaultCoords;
Images = store.getImagesMatching(DefaultCoords.Builder().build()).toArray();

% Parse metadata
metadata = [];
summary = store.getSummaryMetadata();
metadata.channels = char(summary.getChannelNames());
for l = 1:length(Images)
    Coords = Images(l).getCoords();
    Meta = Images(l).getMetadata();
    
    data = struct;
    data.x = Meta.getXPositionUm();
    data.y = Meta.getYPositionUm();
    data.z = Meta.getZPositionUm();
    data.theC = Coords.getChannel();
    data.theZ = Coords.getZ();
    data.theT = Coords.getTime();
    data.exposure = Meta.getExposureMs();
    pos(Coords.getPosition()+1,Coords.getChannel()+1) = data;
    
    metadata.pixelSize = Meta.getPixelSizeUm();
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
    img(:,:,Coords.getPosition()+1,Coords.getChannel()+1) = ...
        reshape(Images(l).getRawPixels, width, height)';
end
        