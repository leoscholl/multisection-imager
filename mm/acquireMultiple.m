function result = acquireMultiple(mm, dir, channels, exposures, channelGroup)
% acquireMultiple Script to drive MicroManager for multidimensional acq

if ~exist('channelGroup', 'var') || isempty(channelGroup)
    channelGroup = 'Reflector';
end

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
	.channel(length(channels)).stagePosition(nPos).time(0).z(0).build());
store.setSummaryMetadata(metadata.build());
mm.core().setTimeoutMs(30000);

% turn off live display
mm.live().setLiveMode(false);
try
    for c = 1:length(channels)
        mm.core().setConfig(channelGroup, channels{c});
        mm.core().waitForConfig(channelGroup, channels{c});
        mm.compat().setExposure(exposures(c));
        
        for l = 1:nPos

            % Go to position
            if mod(c, 2) == 1
                posInd = l - 1;
            else
                posInd = nPos - l;
            end
            pos = pl.getPosition(posInd);
            mm.core().setPosition(pos.getZ());
            mm.core().setXYPosition('XYStage', pos.getX(), pos.getY());
            mm.core().waitForDevice('XYStage');
            mm.core().waitForDevice('Focus');

            % Snap image
            image = mm.live().snap(false).get(0);
            coords = image.getCoords().copy().channel(c-1).stagePosition(posInd).build();
            metadata = image.getMetadata().copy()...
                .xPositionUm(java.lang.Double(pos.getX()))...
                .yPositionUm(java.lang.Double(pos.getY())).build();
            store.putImage(image.copyWith(coords, metadata));
        end
    end
catch e
    result.error = e;
end

% Freeze datastore and move stage away from samples
store.freeze();
if mod(length(channels), 2) == 0
    pos = pl.getPosition(0);
    offset = -30000; % 3 cm
else
    pos = pl.getPosition(nPos-1);
    offset = 30000;
end
mm.core().setXYPosition('XYStage', pos.getX() + offset, pos.getY() + offset);

result.elapsed = toc;
result.store = store;
if isempty(result.error)
    result.status = 1;
end