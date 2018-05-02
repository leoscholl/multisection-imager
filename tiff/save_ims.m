function save_ims(ims, imdata, filepath)

if size(ims,6) == 1 && size(ims,4) > 1
    ims = reshape(ims, size(ims,1), size(ims,2),...
        size(ims,3), 1, 1, size(ims,4));
end
fprintf('saving images...\n');

OMEXMLService = javaObject('loci.formats.services.OMEXMLServiceImpl');
metadata = OMEXMLService.createOMEXMLMetadata();
metadata.createRoot();



nImages = size(ims,6);
for img = 1:nImages
    metadata = createMetadataPerImage(metadata,ims(:,:,:,:,:,img),img-1, 'XYCZT');
    metadata.setPixelsPhysicalSizeX(imdata.pixelSize, img-1);
    metadata.setPixelsPhysicalSizeY(imdata.pixelSize, img-1);

    nPlanes = metadata.getPixelsSizeZ(img-1).getValue() *...
        metadata.getPixelsSizeC(img-1).getValue() *...
        metadata.getPixelsSizeT(img-1).getValue();
    cztCoord = [size(ims, 3) size(ims, 4) size(ims, 5)];
    for index = 1 : nPlanes
        [c, z, t] = ind2sub(cztCoord, index);

        positionX = imdata.pos(img,c,z,t).x;
        positionY = imdata.pos(img,c,z,t).y;
        positionZ = imdata.pos(img,c,z,t).z;
        metadata.setPlanePositionX(positionX, img-1, index-1);
        metadata.setPlanePositionY(positionY, img-1, index-1);
        metadata.setPlanePositionZ(positionZ, img-1, index-1);

        theC = javaObject('ome.xml.model.primitives.NonNegativeInteger', ...
            java.lang.Integer(imdata.pos(img,c,z,t).theC));
        theZ = javaObject('ome.xml.model.primitives.NonNegativeInteger', ...
            java.lang.Integer(imdata.pos(img,c,z,t).theZ));
        theT = javaObject('ome.xml.model.primitives.NonNegativeInteger', ...
            java.lang.Integer(imdata.pos(img,c,z,t).theT));
        metadata.setPlaneTheC(theC,img-1,index-1);
        metadata.setPlaneTheZ(theZ,img-1,index-1);
        metadata.setPlaneTheT(theT,img-1,index-1);

    end
    for c = 1:size(ims, 3)
        metadata.setChannelName(imdata.channels{c},img-1,c-1);
    end
end

bfsave(ims, filepath, 'metadata', metadata, ...
    'dimensionOrder', 'XYCZT', 'BigTiff', true);
fprintf('\ndone.\n');
end