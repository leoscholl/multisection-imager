function rois = segmentSlide(img, imdata)
% Create downsampled fusion
globalPosY = arrayfun(@(s)double(s.y.value), imdata.pos)/double(imdata.pixelSize.value);
globalPosX = arrayfun(@(s)double(s.x.value), imdata.pos)/double(imdata.pixelSize.value);
globalPosY = round(globalPosY(:,1) - min(globalPosY(:,1)) + 1);
globalPosX = round(globalPosX(:,1) - min(globalPosX(:,1)) + 1);

downsample = 10;
I = stitchImg(img, globalPosY, globalPosX, downsample, []);

% Filter and threshold
sigma = 20;
f = imgaussfilt(I(:,:,end), sigma);
f = imbinarize(f, 'global');

% Segment
f = imfill(f, 'holes');
stats = regionprops(f, 'BoundingBox');

% Display
imshow(I(:,:,end));
set(gca,'units','pixels')
x = get(gca,'position');
set(gcf,'units','pixels')
y = get(gcf,'position');
set(gcf,'position',[y(1) y(2) x(3) x(4)])
set(gca,'units','normalized','position',[0 0 1 1])

% Draw bounding boxes
r = [];
for n = 1:length(stats)
    r(n) = imrect(gca, stats(n).BoundingBox);
end

% Wait for user input
btn = uicontrol('Style', 'pushbutton', 'String', 'Looks good!', ...
    'Position', [20 20 50 20], ...
    'Callback', {@updateRois, r});

% Return ROIs

end

function rois = updateRois(src, event, r)

rois = [];
i = 1;
for n = 1:length(r)
    if isvalid(r)
        rois(i,:) = getPosition(r);
    end
end

end