function [I, offset] = stitchImg(img, metadata, downsample, roi, poly, strict)

if ~exist('downsample', 'var') || isempty(downsample)
    downsample = 1;
end
if (~exist('roi', 'var') || isempty(roi)) && (~exist('poly', 'var') || isempty(poly))
    roi = [1 1 Inf Inf];
end
if ~exist('roi', 'var')
    roi = [];
end
if ~exist('poly', 'var')
    poly = [];
    strict = [];
end

imgHeight = ceil(size(img,1)/downsample);
imgWidth = ceil(size(img,2)/downsample);

[globalPosY, globalPosX, inBounds, offset] = calculateBounds(metadata, roi, poly, strict);
inBounds = find(inBounds);

globalPosY = ceil(globalPosY/downsample);
globalPosX = ceil(globalPosX/downsample);
stitchedHeight = max(globalPosY(:)) + imgHeight - 1;
stitchedWidth = max(globalPosX(:)) + imgWidth - 1;
    
% Initialize image
I = zeros(stitchedHeight, stitchedWidth, size(img, 3), 'like', img);
countsI = zeros(stitchedHeight, stitchedWidth, size(img, 3), 'like', img);

% Assemble images
switch class(img)
    case 'logical'
        for n = 1:size(globalPosX,2)
            for c = 1:size(globalPosX,1)
                x_st = globalPosX(c,n);
                x_end = globalPosX(c,n)+imgWidth-1;
                y_st = globalPosY(c,n);
                y_end = globalPosY(c,n)+imgHeight-1;
                I(y_st:y_end,x_st:x_end,c) = or(I(y_st:y_end,x_st:x_end,c), ...
                    img(1:downsample:end,1:downsample:end,c,inBounds(n)));
            end
        end
    otherwise
        for n = 1:size(globalPosX,2)
            for c = 1:size(globalPosX,1)
                x_st = globalPosX(c,n);
                x_end = globalPosX(c,n)+imgWidth-1;
                y_st = globalPosY(c,n);
                y_end = globalPosY(c,n)+imgHeight-1;
                countsI(y_st:y_end,x_st:x_end,c) = countsI(y_st:y_end,x_st:x_end,c) + 1;
            end
        end
        for n = 1:size(globalPosX,2)
            for c = 1:size(globalPosX,1)
                x_st = globalPosX(c,n);
                x_end = globalPosX(c,n)+imgWidth-1;
                y_st = globalPosY(c,n);
                y_end = globalPosY(c,n)+imgHeight-1;
                I(y_st:y_end,x_st:x_end,c) = I(y_st:y_end,x_st:x_end,c) + ...
                    img(1:downsample:end,1:downsample:end,c,inBounds(n))./countsI(y_st:y_end,x_st:x_end,c);
            end
        end
end