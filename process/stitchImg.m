function I = stitchImg(img, globalPosY, globalPosX, downsample, pos)

imgHeight = ceil(size(img,1)/downsample);
imgWidth = ceil(size(img,2)/downsample);
alpha = 1.5;

% Make sure positions are relative to (1,1)
globalPosY = round(globalPosY - min(globalPosY) + 1);
globalPosX = round(globalPosX - min(globalPosX) + 1);
pos([2 4]) = round(pos([2 4]) - min(globalPosY) + 1);
pos([1 3]) = round(pos([1 3]) - min(globalPosX) + 1);

% Determine how big to make the image
inBounds = 1:length(globalPosX);
if exist('pos', 'var') && ~isempty(pos)
    inBoundsY = globalPosY + size(img,2) >= pos(2) & globalPosY < pos(2) + pos(4);
    inBoundsX = globalPosX + size(img,1) >= pos(1) & globalPosX < pos(1) + pos(3);
    inBounds = find(inBoundsX & inBoundsY);
    globalPosY = globalPosY(inBounds);
    globalPosX = globalPosX(inBounds);
    globalPosY = globalPosY - min(globalPosY) + 1;
    globalPosX = globalPosX - min(globalPosX) + 1;
end
globalPosY = ceil(globalPosY/downsample);
globalPosX = ceil(globalPosX/downsample);
stitchedHeight = max(globalPosY(:)) + imgHeight + 1;
stitchedWidth = max(globalPosX(:)) + imgWidth + 1;
    
% Initialize image
I = zeros(stitchedHeight, stitchedWidth, size(img, 3), 'single');
w_mat = single(compute_linear_blend_pixel_weights([imgHeight, imgWidth], alpha));
countsI = zeros(stitchedHeight, stitchedWidth, 'single');

% Assemble images
for n = 1:length(inBounds)
    x_st = globalPosX(n);
    x_end = globalPosX(n)+imgWidth-1;
    y_st = globalPosY(n);
    y_end = globalPosY(n)+imgHeight-1;
    I(y_st:y_end,x_st:x_end,:) = I(y_st:y_end,x_st:x_end,:) + ...
        single(img(1:downsample:end,1:downsample:end,:,inBounds(n))).*w_mat;
    countsI(y_st:y_end,x_st:x_end) = countsI(y_st:y_end,x_st:x_end) + w_mat;
end
I = I./countsI;
I = cast(I, class(img));