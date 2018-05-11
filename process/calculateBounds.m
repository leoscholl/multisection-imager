function [globalPosY, globalPosX, inBounds, offset] = ...
    calculateBounds(imdata, roi, poly, strict)
% calculateBounds Determine the global pixel positions for images of the given
% metadata such that all images are within the ROI or polygon

if ~exist('strict', 'var')
    strict = false;
end

% Generate global positions relative to (1,1)
globalPosY = arrayfun(@(s)s.y, imdata.position)/imdata.pixelSize;
globalPosX = arrayfun(@(s)s.x, imdata.position)/imdata.pixelSize;
offsetY = min(globalPosY(:)) - 1;
offsetX = min(globalPosX(:)) - 1;
globalPosY = round(globalPosY - offsetY);
globalPosX = round(globalPosX - offsetX);

if exist('roi','var') && ~isempty(roi)
    % Make sure roi is relative to (1,1)
    roi([2 4]) = round(roi([2 4]) - min(globalPosY(:)) + 1);
    roi([1 3]) = round(roi([1 3]) - min(globalPosX(:)) + 1);

    % Determine how big to make the image
    if strict
        inBoundsY = mean(globalPosY,1) >= roi(2) & mean(globalPosY,1) < roi(2);
        inBoundsX = mean(globalPosX,1) >= roi(1) & mean(globalPosX,1) < roi(1);
    else
        inBoundsY = mean(globalPosY,1) + imdata.height >= roi(2) & mean(globalPosY,1) < roi(2) + roi(4);
        inBoundsX = mean(globalPosX,1) + imdata.width >= roi(1) & mean(globalPosX,1) < roi(1) + roi(3);
    end
    inBounds = find(inBoundsX & inBoundsY);
elseif exist('poly','var') && ~isempty(poly)
    % Make sure polygon is relative to (1,1)
    poly(:,2) = round(poly(:,2) - min(globalPosY(:)) + 1);
    poly(:,1) = round(poly(:,1) - min(globalPosX(:)) + 1);

    % Determine bounds of image
    inBounds = zeros(1,size(globalPosX,2));
    for n = 1:size(globalPosX,2)
        x = mean(globalPosX(:,n));
        y = mean(globalPosY(:,n));
        xq = [x, x+imdata.width, x, x+imdata.width];
        yq = [y, y+imdata.height, y+imdata.height, y];
        [in, on] = inpolygon(xq, yq, poly(:,1), poly(:,2));
        if strict
            inBounds(n) = all(in | on);
        else
            inBounds(n) = any(in | on);
        end
    end
    inBounds = find(inBounds);
end
globalPosY = globalPosY(:,inBounds);
globalPosX = globalPosX(:,inBounds);
offsetY = min(globalPosY(:)) - 1;
offsetX = min(globalPosX(:)) - 1;
globalPosY = round(globalPosY - offsetY);
globalPosX = round(globalPosX - offsetX);
offset = round([offsetX, offsetY]);

end