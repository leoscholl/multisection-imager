function [I, offset] = stitchImg(img, metadata, downsample, roi)

if ~exist('downsample', 'var') || isempty(downsample)
    downsample = 1;
end
if ~exist('roi', 'var') || isempty(roi)
    roi = [1 1 Inf Inf];
end

imgHeight = ceil(size(img,1)/downsample);
imgWidth = ceil(size(img,2)/downsample);
alpha = 1.5;

[globalPosY, globalPosX, inBounds, offset] = calculateBounds(metadata, roi);

globalPosY = ceil(globalPosY/downsample);
globalPosX = ceil(globalPosX/downsample);
stitchedHeight = max(globalPosY(:)) + imgHeight + 1;
stitchedWidth = max(globalPosX(:)) + imgWidth + 1;
    
% Initialize image
I = zeros(stitchedHeight, stitchedWidth, size(img, 3), 'single');
w_mat = single(compute_linear_blend_pixel_weights([imgHeight, imgWidth], alpha));
countsI = zeros(stitchedHeight, stitchedWidth, size(img, 3), 'single');

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
                    single(img(1:downsample:end,1:downsample:end,c,inBounds(n))));
            end
        end
    otherwise
        for n = 1:size(globalPosX,2)
            for c = 1:size(globalPosX,1)
                x_st = globalPosX(c,n);
                x_end = globalPosX(c,n)+imgWidth-1;
                y_st = globalPosY(c,n);
                y_end = globalPosY(c,n)+imgHeight-1;
                I(y_st:y_end,x_st:x_end,c) = I(y_st:y_end,x_st:x_end,c) + ...
                    single(img(1:downsample:end,1:downsample:end,c,inBounds(n))).*w_mat;
                countsI(y_st:y_end,x_st:x_end,c) = countsI(y_st:y_end,x_st:x_end,c) + w_mat;
            end
        end
        I = I./countsI;
end
I = cast(I, class(img));