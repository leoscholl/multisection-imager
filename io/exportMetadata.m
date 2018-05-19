function exportMetadata(metadata, subject, datadir)
%exportMetadata Save an mat file containing metadata

fprintf('writing mat file...');
[~, filename, ~] = fileparts(metadata.filepath);
filepath = fullfile(datadir, subject, filename, sprintf('%s.mat', filename));
save(filepath,'metadata','-v7.3');
fprintf('\n');