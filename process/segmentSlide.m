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
fig = figure('Visible','off','Name',...
    'Please label each slice and make sure the boundaries are correct');
imshow(I(:,:,end), [min(min(I(:,:,end))), max(max(I(:,:,end)))]);
set(gca,'units','pixels')
x = get(gca,'position');
set(fig,'units','pixels')
y = get(gcf,'position');
set(fig,'position',[y(1), y(2)+y(4)-x(4), x(3), x(4)])
set(gca,'units','normalized','position',[0 0 1 1]);
set(fig,'units','normalized');
s = fliplr(size(I(:,:,end)));

% Draw bounding boxes
% TODO: label bounding boxes with section number
minArea = round(50*10^6/metadata.pixelSize^2/downsample^2);
maxArea = round(500*10^6/metadata.pixelSize^2/downsample^2);
roi = {};
label = {};
i = 1;
for n = 1:length(stats)
    if stats(n).Area > minArea && stats(n).Area < maxArea
        p = stats(n).BoundingBox;
        z = zoom(fig);
        roi{i} = imrect(gca,p);
        addNewPositionCallback(roi{i}, @(p)updateLabel(p, i));
        label{i} = uicontrol(fig, 'Style', 'edit',...
            'Units', 'normalized', 'Position', ...
            [(p(1)+50)/s(1) (s(2)-p(2)-150)/s(2) 10/y(1) 10/y(2)]);
        hull{i} = stats(n).ConvexHull;
        i = i + 1;
    end
end

% Wait for user confirmation
ref = {};
    function addReference(src,event)
        ref{end+1} = impoint(gca);
        uiwait(fig);
    end
    function updateLabel(p, i)
        label{i}.Position = [(p(1)+50)/s(1) (s(2)-p(2)-150)/s(2) 10/y(1) 10/y(2)];
    end

if confirmation
    set(fig,'Visible','on');
    addPt = uicontrol('Style', 'pushbutton', 'String', 'Add reference point...',...
        'Position', [20 20 120 30], 'Callback', @addReference);
    cont = uicontrol('Style', 'pushbutton', 'String', 'Looks good!', ...
        'Position', [150 20 120 30], 'Callback', 'uiresume');
    uiwait(fig);
end

% Collect ROIs with corresponding convex hulls
rois = [];
hulls = [];
i = 1;
for n = 1:length(roi)
    if isvalid(roi{n})
        rois(i,:) = getPosition(roi{n});
        sections(i) = str2double(label{i}.String);
        if isnan(sections(i))
            sections(i) = -i;
        end
        hulls{i} = hull{n};
        i = i + 1;
    end
end

% Collect reference points
refs = zeros(size(rois,1),2);
for n = 1:length(ref)
    if isvalid(ref{n})
        p = getPosition(ref{n});
        % Put this reference point into the same index as its bouding ROI
        i = rois(:,1) < p(1) & rois(:,1) + rois(:,3) > p(1) ...
            & rois(:,2) < p(2) & rois(:,2) + rois(:,4) > p(2);
        refs(i,:) = p;
    end
end
refs = round(refs.*downsample);
rois = round(rois.*downsample);
hulls = cellfun(@(x)round(x.*downsample),hulls,'UniformOutput',false);

close(fig);

metadata.rois = rois;
metadata.sections = sections;
metadata.hulls = hulls;
metadata.refs = refs;

end