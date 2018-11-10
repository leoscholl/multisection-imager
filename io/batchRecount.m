function batchRecount(datadir, exportdir, subject, channelPairs, downsample, metadir)

if ~exist('metadir', 'var') || isempty(metadir)
    metadir = '*';
end

files = dir(fullfile(datadir, subject, metadir, '*.mat'));
for i = 1:length(files)
    fprintf(['Export ', files(i).name, '...\n']);
    f = load(fullfile(files(i).folder, files(i).name));
    if ~isfield(f, 'metadata')
        continue;
    end
    metadata = countCells(f.metadata, channelPairs, downsample);
    save(fullfile(files(i).folder, files(i).name), 'metadata');
    exportMetadataToAsc(metadata, subject, exportdir);
end