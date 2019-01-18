function exportMetadataToAsc(metadata, subject, datadir)
%exportMetadataToAsc Save an ASC format file with metadata information
% regarding reference points, image data, boundaries, and cell markers

if ~isfield(metadata, 'sections')
    error('No section metadata. Exporting requires at least one section');
end
if ~isfield(metadata, 'imagepath') || isempty(metadata.imagepath)
    error('No filepath metadata. Save files before exporting.');
end

msg = '';
for n = 1:length(metadata.sections)
    
    fprintf(repmat('\b',1,length(msg)));
    msg = sprintf('writing asc file %d/%d', n, length(metadata.sections));
    fprintf(msg)
    
    datapath = fullfile(datadir, subject, 'ASC');
    if ~exist(datapath, 'dir')
        mkdir(datapath);
    end
    filename = sprintf('%s Sect %03d.ASC', ...
        subject, metadata.sections(n));
    filepath = fullfile(datapath, filename);
    f = fopen(filepath, 'w');
    
    % Reference point
    ref = [0 0];
    offset = [0 0];
    if isfield(metadata, 'positions') && isfield(metadata, 'boundaries')
        [~, ~, ~, offset] = calculateBounds(metadata, [], metadata.boundaries{n}, false);
    end
    if isfield(metadata, 'refs')
        ref = metadata.refs(n,:) - offset;
    end
    
    % Image metadata
    fprintf(f, ';\tV3 text file written by multisection-imager in MATLAB.\r\n');
    fprintf(f, '(ImageCoords \r\n');
    if isfield(metadata, 'isrgb') && metadata.isrgb
        nChannels = 1;
    else
        nChannels = length(metadata.channels);
    end
    for c = 1:nChannels
        filepath = metadata.imagepath{n,c};
        fprintf(f, ' Filename "%s" Merge 65535 65535 65535 0\r\n', filepath);
        fprintf(f, ' Coords %g %g %g %g %g\r\n', ...
            metadata.pixelSize, metadata.pixelSize,...
            -ref(1)*metadata.pixelSize, ref(2)*metadata.pixelSize, 0);
    end
    fprintf(f, '); End of ImageCoords\r\n\r\n');
    
    % Boundary metadata
    if isfield(metadata, 'boundaries') && ~isempty(metadata.boundaries{n})
        fprintf(f, '("Surface"\r\n  (Color Cyan)\r\n  (Closed)\r\n');
        symbols = ['0':'9','A':'F'];
        nums = randi(length(symbols),[1 32]);
        fprintf(f, '  (GUID "%s")\r\n', strcat(symbols(nums)));
        fprintf(f, '  (MBFObjectType 5)\r\n  (Resolution %f)\r\n',...
            metadata.pixelSize);
        for p = 1:size(metadata.boundaries{n},1)
            fprintf(f, '  (%8.2f %8.2f %8.2f %8.2f)  ;  1, %d\r\n', ...
                (metadata.boundaries{n}(p,1) - offset(1) - ref(1))*metadata.pixelSize, ...
                -(metadata.boundaries{n}(p,2) - offset(2) - ref(2))*metadata.pixelSize, ...
                0, metadata.pixelSize, p);
        end
        fprintf(f, ')  ;  End of contour\r\n\r\n');
    end
    
    % Marker metadata
    if isfield(metadata, 'cells')
        for c = 1:size(metadata.cells,2)
            if isempty(metadata.cells{n,c}.centroid)
                continue;
            end
            switch metadata.imageorder{metadata.cells{n,c}.channel}
                case 'GFP'
                    fprintf(f, '(FilledCircle\r\n  (Color Green)\r\n  (Name "GFP")\r\n');
                case 'mCherry'
                    fprintf(f, '(FilledDownTriangle\r\n  (Color Red)\r\n  (Name "mCherry")\r\n');
                case 'BFP'
                    fprintf(f, '(FilledSquare\r\n  (Color Blue)\r\n  (Name "BFP")\r\n');
            end
            for p = 1:size(metadata.cells{n,c}.centroid,1)
                fprintf(f, '  (%8.2f %8.2f %8.2f %8.2f)  ; %d\r\n', ...
                    (metadata.cells{n,c}.centroid(p,1) - offset(1) - ref(1))*metadata.pixelSize - 5, ...
                    -(metadata.cells{n,c}.centroid(p,2) - offset(2) - ref(2))*metadata.pixelSize - 5, ...
                    0, metadata.cells{n,c}.diameter(p), p);
            end
            fprintf(f, ')  ;  End of markers\r\n\r\n');
        end
    end
    
    fclose(f);
    
end
fprintf('\r\n')