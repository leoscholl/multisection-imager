function writeImages(img, metadata, rois, subject, datadir, sections, suffix, downsample)
% writeImages stitch images per ROI and save to disk
resolution = 10000/metadata.pixelSize; % um/pixel -> pixels/cm
channels = metadata.channels;

if ~exist('downsample', 'var')
    downsample = 1;
end
if ~exist('suffix', 'var')
    suffix = '';
end

msg = '';
for n = 1:size(rois,1)
    
    fprintf(repmat('\b',1,length(msg)));
    msg = sprintf('writing image %d/%d', n, size(rois,1));
    fprintf(msg)
    
    I = stitchImg(img, metadata, downsample, rois(n,:));
    datapath = fullfile(datadir, subject, sprintf('Sect %d', sections(n)));
    if ~exist(datapath, 'dir')
        mkdir(datapath);
    end
    for c = 1:size(I,3)
        filename = sprintf('%s Sect %d %s', ...
            subject, sections(n), channels{c});
        if ~isempty(suffix)
            filename = [filename, ' ', suffix];
        end
        filepath = fullfile(datapath, filename);
        t = Tiff([filepath, '.tiff'], 'w');
        tags = struct;
        tags.ImageLength = size(I,1);
        tags.ImageWidth = size(I,2);
        tags.ResolutionUnit = Tiff.ResolutionUnit.Centimeter;
        tags.XResolution = resolution;
        tags.YResolution = resolution;
        tags.Software = 'MATLAB';
        tags.DocumentName = filename;
        tags.Photometric = Tiff.Photometric.MinIsBlack;
        tags.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
        tags.Compression = Tiff.Compression.LZW;
        switch class(img)
            case 'uint16'
                tags.BitsPerSample = 16;
            case 'uint8'
                tags.BitsPerSample = 8;
            case 'logical'
                tags.BitsPerSample = 1;
            otherwise
                error('Unsupported bit depth')
        end
        tags.RowsPerStrip = round(size(I,2)/8/tags.BitsPerSample);
        tags.SamplesPerPixel = 1;
        setTag(t, tags);
        write(t, I(:,:,c));
        close(t);
    end
end
fprintf('\n')