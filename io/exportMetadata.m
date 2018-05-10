function exportMetadata(metadata, subject, datadir)
%exportMetadata Save an mat file containing metadata

msg = '';
for n = 1:size(metadata.rois,1)
    
    fprintf(repmat('\b',1,length(msg)));
    msg = sprintf('writing asc file %d/%d', n, size(metadata.rois,1));
    fprintf(msg)
    
    datapath = fullfile(datadir, subject, sprintf('Sect %d', metadata.sections(n)));
    if ~exist(datapath, 'dir')
        mkdir(datapath);
    end
    filename = sprintf('%s Sect %d.mat', ...
        subject, metadata.sections(n));
    filepath = fullfile(datapath, filename);
    save(filepath,'metadata','-v7.3');
end
fprintf('\n');