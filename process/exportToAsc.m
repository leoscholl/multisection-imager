function exportToAsc(bimg, metadata, cellMetadata, rois, subject, ...
    datadir, sections, offset)
% exportCellsToAsc stitch images per ROI and save cells to ASC format

if ~exist('offset', 'var') || isempty(offset)
    offset = [0 0];
end

msg = '';
for n = 1:size(rois,1)
    
    fprintf(repmat('\b',1,length(msg)));
    msg = sprintf('writing image %d/%d', n, size(rois,1));
    fprintf(msg)
    
    datapath = fullfile(datadir, subject, sprintf('Sect %d', sections(n)));
    if ~exist(datapath, 'dir')
        mkdir(datapath);
    end
    filename = sprintf('%s Sect %d.ASC', ...
        subject, sections(n));
    filepath = fullfile(datapath, filename);
    f = fopen(filepath, 'w');
    
    if exist('bimg', 'var') && ~isempty(bimg)
        I = stitchImg(bimg, cellMetadata, 1, rois(n,:));
    end
     
    fprintf(f, ';\tV3 text file written by multisection-imager in MATLAB.\n');
    fprintf(f, '(ImageCoords \n');
    for c = 1:length(metadata.channels)
        filename = sprintf('%s Sect %d %s.tiff', ...
            subject, sections(n), metadata.channels{c});
        filepath = fullfile(datapath, filename);
        fprintf(f, 'Filename "%s" Merge 65535 65535 65535 0\n', filepath);
        fprintf(f, 'Coords %f %f %f %f %f\n', ...
            metadata.pixelSize, metadata.pixelSize,...
            offset(1), offset(2), 0);
    end
    fprintf(f, '); End of ImageCoords\n\n');
    
    if exist('bimg', 'var') && ~isempty(bimg)
        for c = 1:length(cellMetadata.channels)
            stats = regionprops(I(:,:,c), 'Centroid');

            switch cellMetadata.channels{c}
                case 'GFP'
                    fprintf(f, '(FilledCircle\n  (Color Green)\n  (Name "GFP")\n');
                case 'mCherry'
                    fprintf(f, '(FilledDownTriangle\n  (Color Red)\n  (Name "mCherry")\n');
                case 'BFP'
                    fprintf(f, '(FilledSquare\n  (Color Blue)\n  (Name "BFP")\n');
            end
            for s = 1:length(stats)
                fprintf(f, '  (%.2f %.2f %.2f %.2f)  ; %d\n', ...
                    (stats(s).Centroid(1) + offset(1))*metadata.pixelSize, ...
                    -(stats(s).Centroid(2) + offset(2))*metadata.pixelSize, ...
                    0, 0, s);
            end
            fprintf(f, ')  ;  End of markers\n\n');
        end
    end

    fclose(f);

end
fprintf('\n')