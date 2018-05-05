function status = checkPositionList(mm)
% checkPositionList Make sure a position list has been set
pl = mm.getPositionList();
if pl.getNumberOfPositions() < 1
    status = 0;
else
    status = 1;
end