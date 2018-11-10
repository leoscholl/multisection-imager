function generateMetadata(datadir, subject, filter, pixelSize)
metadata = struct;

if exist('pixelSize', 'var')
    metadata.pixelSize = pixelSize;
else
    metadata.pixelSize = 1.301911;
end

if ~exist('filter', 'var')
    filter = '*.jp2';
end

images = dir(fullfile(datadir, subject, '*', filter));
if isempty(images)
    return;
end

sections = cellfun(@(c)regexpi(c, '[\s_](\d+)[\s_]','tokens'),{images.name},'un',0);
sections = cellfun(@(c)str2double(c{1}{1}),sections);
metadata.sections = unique(sections);

channels = cellfun(@(c)regexpi(c, '\d+[\s_](\w+)\.','tokens'),{images.name},'un',0);
channels = cellfun(@(c)c{1}{1},channels,'un',0);
metadata.channels = unique(channels);

metadata.imagepath = cell(length(metadata.sections),length(metadata.channels));
for c = 1:length(metadata.channels)
    channel = metadata.channels{c};
    sub = ismember(channels, channel);
    for n = 1:sum(sub)
        subsections = sections(sub);
        subimages = images(sub);
        metadata.sections(n) = subsections(n);
        metadata.imagepath{n,c} = fullfile(subimages(n).folder, subimages(n).name);
    end
end

metadata.rois = nan(length(metadata.sections),4);
metadata.boundaries = cell(length(metadata.sections),1);
metadata.refs = nan(length(metadata.sections),2);
for n = 1:length(metadata.sections)
    I = imread(metadata.imagepath{n,end});
    downsample = ceil(length(I)/500); % ideal size 500x500
    I = I(1:downsample:end,1:downsample:end);
    [rois, sections, boundaries, refs] = slide_segmenter(I,...
        max(1,50/downsample), true, ['Section ', num2str(metadata.sections(n))]);
    area = times(rois(:,3),rois(:,4));
    [~, biggest] = max(area);
    metadata.rois(n,:) = rois(biggest,:).*downsample;
    metadata.boundaries{n} = fliplr(boundaries{biggest}).*downsample;
    metadata.refs(n,:) = refs(biggest,:).*downsample;
end

savedir = fullfile(datadir, subject, 'metadata');
if ~exist(savedir, 'dir')
    mkdir(savedir);
end
save(fullfile(savedir, [subject '.mat']), 'metadata');