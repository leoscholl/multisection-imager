function result = acquireMultiple(mm, dir, channels, exposures)
% acquireMultiple Script to drive MicroManager for multidimensional acq

tic;
result = [];
result.error = [];
result.status = 0;

% Set up datastore
dir = mm.data().getUniqueSaveDirectory(dir);
store = mm.data().createMultipageTIFFDatastore(dir, false, false);
display = mm.displays().createDisplay(store);
mm.displays().manage(store);

% create acquisition and set options
pl = mm.compat().getPositionList();
nPos = pl.getNumberOfPositions();
metadata = store.getSummaryMetadata().copy();
metadata.channelGroup(channelGroup);
metadata.channelNames(channels);
metadata.stagePositions(pl.getPositions());
metadata.intendedDimensions(...
	mm.data().getCoordsBuilder()...
	.channel(channels.length).stagePosition(nPos).time(0).z(0).build());
store.setSummaryMetadata(metadata.build());
mm.core().setTimeoutMs(30000);

% turn off live display
mm.live().setLiveMode(false);
error = [];
try
    for ch = 1:length(channels)
        core.setConfig(channelGroup, channels{ch});
        core.waitForConfig(channelGroup, channels{ch});
        mm.setExposure(exposures(ch));
        
        for l = 1:nPos

            % Go to position
            if mod(ch, 2) == 1
                posInd = l - 1;
            else
                posInd = nPos - l;
            end
            pos = pl.getPosition(posInd);
            core.setPosition(pos.getZ());
            core.setXYPosition('XYStage', pos.getX(), pos.getY());
            core.waitForDevice('XYStage');
            core.waitForDevice('Focus');

            % Snap image
            image = mm.live().snap(false).get(0);
            coords = image.getCoords().copy().channel(c-1).stagePosition(posInd).build();
            metadata = image.getMetadata().copy().xPositionUm(pos.getX()).yPositionUm(pos.getY()).build();
            store.putImage(image.copyWith(coords, metadata));
            i = i+1;
        end
    end
catch e
    result.error = e;
end

% Freeze datastore and move stage away from samples
store.freeze();
if mod(length(channels), 2) == 0
    pos = pl.getPosition(0);
    offset = -10000;
else
    pos = pl.getPosition(nPos-1);
    offset = 10000;
end
mm.core().setRelativeXYPosition('XYStage', pos.getX() + offset, pos.getY() + offset);

result.elapsed = toc;
result.store = store;
if isempty(result.error)
    result.status = 1;
end