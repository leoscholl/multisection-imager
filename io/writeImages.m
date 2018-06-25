function metadata = writeImages(img, metadata, subject, datadir, downsample)
% writeImages stitch images per ROI and save to disk
resolution = 10000/metadata.pixelSize; % um/pixel -> pixels/cm
channels = metadata.channels;

if ~exist('downsample', 'var')
    downsample = 1;
end

msg = '';
for n = 1:size(metadata.boundaries,1)
    
    fprintf(repmat('\b',1,length(msg)));
    msg = sprintf('stitching & writing %d images for section %d/%d', ...
         size(img,3), n, size(metadata.boundaries,1));
    fprintf(msg)
    
    I = stitchImg(img, metadata, downsample, [], metadata.boundaries{n}, false);
    datapath = fullfile(datadir, subject, sprintf('Sect %d', metadata.sections(n)));
    if ~exist(datapath, 'dir')
        mkdir(datapath);
    end
    for c = 1:size(I,3)
        filename = sprintf('%s Sect %d %s.tiff', ...
            subject, metadata.sections(n), channels{c});
        filepath = fullfile(datapath, filename);
        metadata.imagepath{n,c} = filepath;
        t = Tiff(filepath, 'w');
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