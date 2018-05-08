function exportToAsc(bimg, metadata, cellMetadata, subject, ...
    datadir, sections)
% exportCellsToAsc stitch images per ROI and save cells to ASC format

if ~isfield(metadata, 'rois')
    error('No ROI metadata. Exporting requires at least one ROI');
end

msg = '';
for n = 1:size(metadata.rois,1)
    
    fprintf(repmat('\b',1,length(msg)));
    msg = sprintf('writing image %d/%d', n, size(metadata.rois,1));
    fprintf(msg)
    
    datapath = fullfile(datadir, subject, sprintf('Sect %d', sections(n)));
    if ~exist(datapath, 'dir')
        mkdir(datapath);
    end
    filename = sprintf('%s Sect %d.ASC', ...
        subject, sections(n));
    filepath = fullfile(datapath, filename);
    f = fopen(filepath, 'w');
    
    % Reference point
    ref = [0 0];
    if isfield(metadata, 'refs')
        ref = metadata.refs(n,:);
    end
    
    % Image metadata
    fprintf(f, ';\tV3 text file written by multisection-imager in MATLAB.\n');
    fprintf(f, '(ImageCoords \n');
    for c = 1:length(metadata.channels)
        filename = sprintf('%s Sect %d %s.tiff', ...
            subject, sections(n), metadata.channels{c});
        filepath = fullfile(datapath, filename);
        fprintf(f, 'Filename "%s" Merge 65535 65535 65535 0\n', filepath);
        fprintf(f, 'Coords %f %f %f %f %f\n', ...
            metadata.pixelSize, metadata.pixelSize,...
            ref(1)*metadata.pixelSize, ref(2)*metadata.pixelSize, 0);
    end
    fprintf(f, '); End of ImageCoords\n\n');
    
    % Convex hull metadata
    if isfield(metadata, 'hulls')
        fprintf(f, '("Surface"\n  (Color Cyan)\n  (Closed)\n');
        symbols = ['0':'9','A':'F'];
        nums = randi(length(symbols),[1 32]);
        fprintf(f, '  (GUID "%s")\n', strcat(symbols(nums)));
        fprintf(f, '  (MBFObjectType 5)\n  (Resolution %f)\n',...
            metadata.pixelSize);
        for p = 1:size(metadata.hulls(:,:,n),1)
            fprintf(f, '  (%.2f %.2f %.2f %.2f)  ;  1, %d\n', ...
                (metadata.hulls(p,1,n) + ref(1))*metadata.pixelSize, ...
                -(metadata.hulls(p,2,n) + ref(2))*metadata.pixelSize, ...
                0, metadata.pixelSize, p);
        end
        fprintf(f, ')  ;  End of contour\n\n');
    end
    
    % Marker metadata
    if exist('bimg', 'var') && ~isempty(bimg)
        I = stitchImg(bimg, cellMetadata, 1, metadata.rois(n,:));
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
                    (stats(s).Centroid(1) + ref(1))*metadata.pixelSize, ...
                    -(stats(s).Centroid(2) + ref(2))*metadata.pixelSize, ...
                    0, 0, s);
            end
            fprintf(f, ')  ;  End of markers\n\n');
        end
    end
    
    fclose(f);
    
end
fprintf('\n')