function metadata = writeImages(img, metadata, subject, datadir, ...
    downsample, rgb)
% writeImages stitch images per ROI and save to disk
resolution = 10000/metadata.pixelSize; % um/pixel -> pixels/cm
channels = metadata.channels;

if ~exist('downsample', 'var') || isempty(downsample)
    downsample = 1;
end

if ~exist('rgb', 'var')
    rgb = false;
end

if exist('img', 'var') && ~isempty(img)
    metadata.imagepath = {};
end

msg = '';
for n = 1:length(metadata.boundaries)
    
    fprintf(repmat('\b',1,length(msg)));
    msg = sprintf('stitching & writing %d images for section %d/%d', ...
         length(metadata.channels), n, length(metadata.boundaries));
    fprintf(msg)
    
    if exist('img', 'var') && ~isempty(img)
        I = stitchImg(img, metadata, downsample, [], metadata.boundaries{n}, false);
    else
        clearvars I
        for c = 1:size(metadata.imagepath,2)
            I(:,:,c) = imread(metadata.imagepath{n,c});
        end
        I = I(1:downsample:end,1:downsample:end,:);
    end
    
    if rgb
        % Order the image into RGB
        I_ = zeros(size(I,1), size(I,2), 3, 'like', I);
        imageorder = {};
        for c = 1:length(channels)
            switch channels{c}
                case 'mCherry'
                    I_(:,:,1) = I(:,:,c);
                    imageorder{1} = 'mCherry';
                case 'GFP'
                    I_(:,:,2) = I(:,:,c);
                    imageorder{2} = 'GFP';
                case 'BFP'
                    I_(:,:,3) = I(:,:,c);
                    imageorder{3} = 'BFP';
            end
        end
        metadata.imageorder = imageorder(~cellfun(@isempty,imageorder));
        metadata.isrgb = true;
        datapath = fullfile(datadir, subject, 'images');
        if ~exist(datapath, 'dir')
            mkdir(datapath);
        end
        filename = sprintf('%s Sect %03d %s.tiff', ...
            subject, metadata.sections(n), strjoin(channels, ' '));
        filepath = fullfile(datapath, filename);
        metadata.imagepath{n,1} = filepath;
        
        t = Tiff(filepath, 'w');
        tags = struct;
        tags.ImageLength = size(I_,1);
        tags.ImageWidth = size(I_,2);
        tags.ResolutionUnit = Tiff.ResolutionUnit.Centimeter;
        tags.XResolution = resolution;
        tags.YResolution = resolution;
        tags.Software = 'MATLAB';
        tags.DocumentName = filename;
        tags.Photometric = Tiff.Photometric.RGB;
        tags.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
        tags.Compression = Tiff.Compression.LZW;
        switch class(I_)
            case 'uint16'
                tags.BitsPerSample = 16;
            case 'uint8'
                tags.BitsPerSample = 8;
            case 'logical'
                tags.BitsPerSample = 1;
            otherwise
                error('Unsupported bit depth')
        end
        tags.RowsPerStrip = round(size(I_,2)/8/tags.BitsPerSample);
        tags.SamplesPerPixel = 3;
        setTag(t, tags);
        write(t, I_);
        close(t);
    else
        for c = 1:size(I,3)
            datapath = fullfile(datadir, subject, channels{c});
            if ~exist(datapath, 'dir')
                mkdir(datapath);
            end
            filename = sprintf('%s Sect %03d %s.tiff', ...
                subject, metadata.sections(n), channels{c});
            filepath = fullfile(datapath, filename);
            metadata.imagepath{n,c} = filepath;
            metadata.imageorder = metadata.channels;
            metadata.isrgb = false;

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
            switch class(I)
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
end
fprintf('\n')