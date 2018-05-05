% Display an image in micromanager
store = mm.data().createRAMDatastore();
display = mm.displays().createDisplay(store);
mm.displays().manage(store);

summary = store.getSummaryMetadata().copy();
summary.channelGroup('Reflector');
summary.channelNames(imdata.channels);
summary.intendedDimensions( ...
	mm.data().getCoordsBuilder() ...
	.channel(length(imdata.channels)).stagePosition(0).time(0).z(0).build());
store.setSummaryMetadata(summary.build());

for c = 1:size(I,3)
    coords = mm.data().getCoordsBuilder();
    coords = coords.channel(c).build();
    metadata = mm.data().getMetadataBuilder();
    metadata = metadata.pixelSizeUm(imdata.pixelSize.value).build();
    image = mm.data().createImage(reshape(I(:,:,c).',[],1), ...
        size(I,2), size(I,1), 1, 1, coords, metadata);
    store.putImage(image);
end

store.freeze();
