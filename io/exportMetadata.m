function exportMetadata(metadata, filepath)
%exportMetadata Save an mat file containing metadata

fprintf('writing mat file...');
save(filepath,'metadata','-v7.3');
fprintf('\n');