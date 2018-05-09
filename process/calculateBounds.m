function [globalPosY, globalPosX, inBounds, offset] = calculateBounds(imdata, roi)
% calculateBounds Determine the global pixel positions for images of the given
% metadata such that all images are within the ROI

% Generate global positions relative to (1,1)
globalPosY = arrayfun(@(s)s.y, imdata.position)/imdata.pixelSize;
globalPosX = arrayfun(@(s)s.x, imdata.position)/imdata.pixelSize;
offsetY = min(globalPosY(:)) - 1;
offsetX = min(globalPosX(:)) - 1;
globalPosY = round(globalPosY - offsetY);
globalPosX = round(globalPosX - offsetX);

% Make sure roi is relative to (1,1)
roi([2 4]) = round(roi([2 4]) - min(globalPosY(:)) + 1);
roi([1 3]) = round(roi([1 3]) - min(globalPosX(:)) + 1);

% Determine how big to make the image
inBoundsY = mean(globalPosY,1) + imdata.height >= roi(2) & mean(globalPosY,1) < roi(2) + roi(4);
inBoundsX = mean(globalPosX,1) + imdata.width >= roi(1) & mean(globalPosX,1) < roi(1) + roi(3);
inBounds = find(inBoundsX & inBoundsY);
globalPosY = globalPosY(:,inBounds);
globalPosX = globalPosX(:,inBounds);
offsetY = min(globalPosY(:)) - 1;
offsetX = min(globalPosX(:)) - 1;
globalPosY = round(globalPosY - offsetY);
globalPosX = round(globalPosX - offsetX);
offset = round([offsetX, offsetY]);

end