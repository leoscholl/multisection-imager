function metadata = convertOmeMetadata(omeMeta)

if ~iscell(omeMeta)
    omeMeta = {omeMeta};
end

metadata.channels = {};
for c = 1:omeMeta{1}.getChannelCount(0)
    metadata.channels{c} = char(omeMeta{1}.getChannelName(0,c-1));
end
metadata.pixelSize = omeMeta{1}.getPixelsPhysicalSizeX(0);

i = 1;
for f = 1:length(omeMeta)
    for img = 1:omeMeta{f}.getImageCount()
        for c = 1:omeMeta{f}.getChannelCount(img-1)
            pos(i,c).x = omeMeta{f}.getPlanePositionX(img-1,c-1);
            pos(i,c).y = omeMeta{f}.getPlanePositionY(img-1,c-1);
            pos(i,c).z = omeMeta{f}.getPlanePositionZ(img-1,c-1);
            pos(i,c).theC = c-1;
            pos(i,c).theZ = 0;
            pos(i,c).theT = 0;
        end
        i = i + 1;
    end
end
metadata.pos = pos;

end