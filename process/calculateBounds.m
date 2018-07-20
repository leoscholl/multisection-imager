function [globalPosY, globalPosX, inBounds, offset] = ...
    calculateBounds(metadata, roi, poly, strict)
% calculateBounds Determine the global pixel positions for images of the given
% metadata such that all images are within the ROI or polygon

if ~exist('strict', 'var')
    strict = false;
end

% Generate global positions relative to (1,1)
globalPosY = arrayfun(@(s)s.y, metadata.position)/metadata.pixelSize;
globalPosX = arrayfun(@(s)s.x, metadata.position)/metadata.pixelSize;
offsetY = min(globalPosY(:)) - 1;
offsetX = min(globalPosX(:)) - 1;
globalPosY = round(globalPosY - offsetY);
globalPosX = round(globalPosX - offsetX);

if exist('roi','var') && ~isempty(roi)
    roi = round(roi);

    % Determine how big to make the image
    if strict
        inBoundsY = mean(globalPosY,1) >= roi(2) & mean(globalPosY,1) < roi(2);
        inBoundsX = mean(globalPosX,1) >= roi(1) & mean(globalPosX,1) < roi(1);
    else
        inBoundsY = mean(globalPosY,1) + metadata.height >= roi(2) & mean(globalPosY,1) < roi(2) + roi(4);
        inBoundsX = mean(globalPosX,1) + metadata.width >= roi(1) & mean(globalPosX,1) < roi(1) + roi(3);
    end
    inBounds = inBoundsX & inBoundsY;
elseif exist('poly','var') && ~isempty(poly)
    poly = round(poly);

    % Determine bounds of image
    inBounds = false(1,size(globalPosX,2));
    for n = 1:size(globalPosX,2)
        x = mean(globalPosX(:,n));
        y = mean(globalPosY(:,n));
        xq = [x, x+metadata.width, x, x+metadata.width];
        yq = [y, y+metadata.height, y+metadata.height, y];
        [in, on] = inpolygon(xq, yq, poly(:,1), poly(:,2));
        if strict
            inBounds(n) = all(in | on);
        else
            inBounds(n) = any(in | on);
        end
    end
end
globalPosY = globalPosY(:,inBounds);
globalPosX = globalPosX(:,inBounds);
offsetY = min(globalPosY(:)) - 1;
offsetX = min(globalPosX(:)) - 1;
globalPosY = round(globalPosY - offsetY);
globalPosX = round(globalPosX - offsetX);
offset = round([offsetX, offsetY]);

end