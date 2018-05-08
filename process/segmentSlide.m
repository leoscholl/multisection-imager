function metadata = segmentSlide(img, metadata, downsample, confirmation)
% segmentSlide determine ROIs automatically or with user confirmation

if ~exist('downsample', 'var') || isempty(downsample)
    downsample = 10;
end
if ~exist('confirmation', 'var') || isempty(confirmation)
    confirmation = true;
end

% Create downsampled fusion
I = stitchImg(img, metadata, downsample, []);

% Filter and threshold
sigma = 20;
f = imgaussfilt(I(:,:,end), sigma);
f = imbinarize(f, 'global');

% Segment
f = imfill(f, 'holes');
stats = regionprops(f, 'BoundingBox', 'Area', 'ConvexHull');

% Display
fig = figure;
imshow(I(:,:,end), [min(min(I(:,:,end))), max(max(I(:,:,end)))]);
set(gca,'units','pixels')
x = get(gca,'position');
set(gcf,'units','pixels')
y = get(gcf,'position');
set(gcf,'position',[y(1), y(2)+y(4)-x(4), x(3), x(4)])
set(gca,'units','normalized','position',[0 0 1 1])

% Draw bounding boxes
minArea = round(50*10^6/metadata.pixelSize^2/downsample^2);
maxArea = round(500*10^6/metadata.pixelSize^2/downsample^2);
roi = {};
i = 1;
for n = 1:length(stats)
    if stats(n).Area > minArea && stats(n).Area < maxArea
        roi{i} = imrect(gca, stats(n).BoundingBox);
        hull{i} = stats(n).ConvexHull;
        i = i + 1;
    end
end

% Wait for user confirmation
ref = {};
function addReference(src,event)
    ref{end+1} = impoint;
end
if confirmation
    addPt = uicontrol('Style', 'pushbutton', 'String', 'Add reference point...',...
        'Position', [20 20 100 30], 'Callback', @addReference);
    cont = uicontrol('Style', 'pushbutton', 'String', 'Looks good!', ...
        'Position', [140 20 100 30], 'Callback', 'uiresume');
    uiwait;
end

% Collect ROIs with corresponding convex hulls
rois = [];
hulls = [];
i = 1;
for n = 1:length(roi)
    if isvalid(roi{n})
        rois(i,:) = getPosition(roi{n});
        hulls(:,:,i) = hull{n};
        i = i + 1;
    end
end
rois = round(rois.*downsample);
hulls = round(hulls.*downsample);

% Collect reference points
refs = [];
i = 1;
for n = 1:length(ref)
    if isvalid(ref{n})
        refs(i,:) = getPosition(ref{n});
        i = i + 1;
    end
end
refs = round(refs.*downsample);

% Sort in slide order
tolerance = round(3000/metadata.pixelSize);
[rois, idx] = sortRowsTol(rois, tolerance);
hulls = hulls(:,:,idx);
refs = sortRowsTol(refs, tolerance);

close(fig);

metadata.rois = rois;
metadata.hulls = hulls;
metadata.refs = refs;

end

function [rois, idx] = sortRowsTol(rois, tolerance)
% sortRois Sorts rows by column with given tolerance
remaining = rois;
idx = zeros(size(rois,1),1);
for n = 1:size(rois,1)
    % find the next roi
    minX = min(remaining(:,1));
    next = 1;
    nextY = remaining(next,2);
    for r = 1:size(remaining,1)
        if remaining(r,1) < minX + tolerance && ...
                remaining(r,2) < nextY
            next = r;
            nextY = remaining(next,2);
        end
    end
    idx(n) = next;
    remaining = remaining([1:next-1,next+1:end],:);
end
rois = rois(idx,:);
end