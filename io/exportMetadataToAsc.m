function exportMetadataToAsc(metadata, subject, datadir)
%exportMetadataToAsc Save an ASC format file with metadata information
% regarding reference points, image data, convex hulls, and cell markers

if ~isfield(metadata, 'sections')
    error('No section metadata. Exporting requires at least one section');
end
if ~isfield(metadata, 'imagepath') || isempty(metadata.imagepath) || ...
    size(metadata.imagepath,1) < size(metadata.rois,1) || ...
    size(metadata.imagepath,2) < length(metadata.channels)
    error('No filepath metadata. Save files before exporting.');
end

msg = '';
for n = 1:length(metadata.sections)
    
    fprintf(repmat('\b',1,length(msg)));
    msg = sprintf('writing asc file %d/%d', n, size(metadata.sections,1));
    fprintf(msg)
    
    datapath = fullfile(datadir, subject, 'ASC');
    if ~exist(datapath, 'dir')
        mkdir(datapath);
    end
    filename = sprintf('%s Sect %d.ASC', ...
        subject, metadata.sections(n));
    filepath = fullfile(datapath, filename);
    f = fopen(filepath, 'w');
    
    % Reference point
    ref = [0 0];
    offset = [0 0];
    if isfield(metadata, 'rois')
        [~, ~, ~, offset] = calculateBounds(metadata, metadata.rois(n,:));
    end
    if isfield(metadata, 'refs')
        ref = metadata.refs(n,:) - offset;
    end
    
    % Image metadata
    fprintf(f, ';\tV3 text file written by multisection-imager in MATLAB.\n');
    fprintf(f, '(ImageCoords \n');
    for c = 1:length(metadata.channels)
        filepath = metadata.imagepath{n,c};
        fprintf(f, 'Filename "%s" Merge 65535 65535 65535 0\n', filepath);
        fprintf(f, 'Coords %f %f %f %f %f\n', ...
            metadata.pixelSize, metadata.pixelSize,...
            ref(1)*metadata.pixelSize, -ref(2)*metadata.pixelSize, 0);
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
        for p = 1:size(metadata.hulls{n},1)
            fprintf(f, '  (%.2f %.2f %.2f %.2f)  ;  1, %d\n', ...
                (metadata.hulls{n}(p,1) - offset(1) + ref(1))*metadata.pixelSize, ...
                -(metadata.hulls{n}(p,2) - offset(2) + ref(2))*metadata.pixelSize, ...
                0, metadata.pixelSize, p);
        end
        fprintf(f, ')  ;  End of contour\n\n');
    end
    
    % Marker metadata
    if isfield(metadata, 'cells')
        for c = 1:size(metadata.cells(n,:))
            switch metadata.channels{metadata.cells{n,c}.channel}
                case 'GFP'
                    fprintf(f, '(FilledCircle\n  (Color Green)\n  (Name "GFP")\n');
                case 'mCherry'
                    fprintf(f, '(FilledDownTriangle\n  (Color Red)\n  (Name "mCherry")\n');
                case 'BFP'
                    fprintf(f, '(FilledSquare\n  (Color Blue)\n  (Name "BFP")\n');
            end
            for p = 1:length(metadata.cells{n,c}.centroid)
                fprintf(f, '  (%.2f %.2f %.2f %.2f)  ; %d\n', ...
                    (metadata.cells{n,c}.centroid(p,1) + ref(1))*metadata.pixelSize, ...
                    -(metadata.cells{n,c}.centroid(p,2) + ref(2))*metadata.pixelSize, ...
                    0, 0, p);
            end
            fprintf(f, ')  ;  End of markers\n\n');
        end
    end
    
    fclose(f);
    
end
fprintf('\n')