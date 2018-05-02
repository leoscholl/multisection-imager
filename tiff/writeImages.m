animal = 'LSR1801';
datadir = 'I:/Test';
numbers = [998];
channels = imdata.channels;
imdata = 3;
resolution = 10000/imdata.pixelSize; % um/pixel -> pixels/cm
downsample = 1;
for n = 1:size(rois,1)
    I = stitchImg(proc, globalPosY, globalPosX, downsample, rois(n,:));
    datapath = fullfile(datadir, animal, sprintf('Sect %d', numbers(n)));
    if ~exist(datapath, 'dir')
        mkdir(datapath);
    end
    for c = 1:size(I,3)
        filename = sprintf('%s Sect %d %s', ...
            animal, numbers(n), channels{c});
        filepath = fullfile(datapath, filename);
        t = Tiff([filepath, '.tiff'], 'w');
        tags = struct;
        tags.ImageLength = size(I,1);
        tags.ImageWidth = size(I,2);
        tags.ResolutionUnit = Tiff.ResolutionUnit.Centimeter;
        tags.XResolution = resolution;
        tags.YResolution = resolution;
        tags.Software = 'MATLAB';
        tags.Compression = Tiff.Compression.LZW;
        tags.DocumentName = filename;
        tags.Photometric = Tiff.Photometric.MinIsBlack;
        tags.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
        tags.BitsPerSample = 8;
        tags.RowsPerStrip = round(size(I,2)/128);
        tags.SamplesPerPixel = 1;
        setTag(t, tags);
        write(t, I(:,:,c));
        close(t);
    end
end