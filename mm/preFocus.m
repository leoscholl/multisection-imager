function preFocus(mm, gridSize)
% preFocus Set the focus at gridSize x gridSize positions, then interpolate
% remaining positions using splines

pl = mm.compat().getPositionList();
nPos = pl.getNumberOfPositions();

% Determine how many rows and cols
rows = 1;
cols = 1;
for l = 1:nPos
    cols = max(cols, pl.getPosition(l-1).getGridColumn()+1);
    rows = max(rows, pl.getPosition(l-1).getGridRow()+1);
end

if ~exist('gridSize', 'var') || isempty(gridSize) || any(gridSize < 3)
    gridRows = max(3, floor(rows/12));
    gridCols = max(3, floor(cols/12));
    gridSize = [gridRows gridCols];
end

% Pick which positions to focus
rowSpacing = rows/(gridSize(1)+1);
colSpacing = cols/(gridSize(2)+1);
[focusCol, focusRow] = meshgrid(round(1+colSpacing:colSpacing:cols),...
    round(1+rowSpacing:rowSpacing:rows));
focusVal = zeros(size(focusCol));

% Turn on live display
mm.live().setLiveMode(true);
mm.core().setTimeoutMs(30000);
oldSpeed = mm.core().getProperty('XYStage', 'Speed');
oldAccel = mm.core().getProperty('XYStage', 'Acceleration');
mm.core().setProperty('XYStage', 'Speed', 5000);
mm.core().setProperty('XYStage', 'Acceleration', 5);

% Do the prefocus routine
for rowInd=1:size(focusRow, 1)
    row = size(focusCol,1) - rowInd + 1;
    for colInd=1:size(focusCol, 2)
        % Go in reverse for odd rows
        if mod(row,2) == mod(size(focusRow,1),2)
            col = size(focusCol,2) - colInd + 1;
        else
            col = colInd;
        end
        pos = getPositionByGrid(pl, focusRow(row, col), focusCol(row, col));
        mm.core().setXYPosition('XYStage', pos.getX(), pos.getY());
        mm.core().waitForDevice('XYStage');
        h = msgbox(sprintf('Focus at or near the current position (%d of %d)', ...
            colInd+size(focusCol,2)*(rowInd-1), size(focusRow,1)*size(focusRow,2)));
        uiwait(h);
        focusVal(row, col) = mm.core().getPosition();
    end
end

% Turn off live mode
mm.live().setLiveMode(false);
windows = mm.displays().getAllImageWindows().toArray();
for w = 1:length(windows)
    name = char(windows(w).getName());
    if strcmp(name, 'Snap/Live View')
        windows(w).requestToClose();
    end
end
mm.core().setProperty('XYStage', 'Speed', oldSpeed);
mm.core().setProperty('XYStage', 'Acceleration', oldAccel);

[Col, Row] = meshgrid(1:cols,1:rows);
F = scatteredInterpolant(focusCol(:), focusRow(:), focusVal(:));
focusInterp = F(Col, Row);

% Replace each Z with the interpolated value
for l = 1:pl.getNumberOfPositions()
    pos = pl.getPosition(l-1);
    row = pos.getGridRow() + 1;
    col = pos.getGridColumn() + 1;
    pl.replacePosition(l-1, replaceZ(pos, focusInterp(row, col)));
end
   
% Update the position list in the GUI
mm.compat().setPositionList(pl);

% Display a verification figure
figure('Name','Focus grid')
imagesc(focusInterp);
xlabel('Grid column')
ylabel('Grid row')
colormap jet; colorbar

end

function [pos, l] = getPositionByGrid(pl, row, col)
% getPositionByGrid Return the position whose column and row match the
% given column and row
for l = 0:pl.getNumberOfPositions()-1
    pos = pl.getPosition(l);
    if row - 1 == pos.getGridRow() && col - 1 == pos.getGridColumn()
        return;
    end
end
pos = [];
l = -1;
end

function newPos = replaceZ(pos, Z)
% replaceZ Update the Z of the given position
import org.micromanager.MultiStagePosition;
xyStage = pos.getDefaultXYStage();
zStage = pos.getDefaultZStage();
properties = pos.getPropertyNames();
newPos = MultiStagePosition(xyStage, pos.getX(), pos.getY(), zStage, Z);
newPos.setLabel(pos.getLabel());
newPos.setGridCoordinates(pos.getGridRow(),pos.getGridColumn());
for p = 1:properties.length
    newPos.setProperty(properties(p), pos.getProperty(properties(p)));
end
return;
end