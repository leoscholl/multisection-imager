function updateFlats(flats, channels, background, filepath)
%updateFlats Create a new flatfields structure at the given filepath

flatfields = [];
if any(~ismember({'GFP','mCherry','BFP'},channels))
    error('All channels must be present');
end
for i = 1:length(channels)
    flatfields.(channels{i}) = flats(:,:,i);
end

if exist('background', 'var') && ~isempty(background)
    if exist(filepath, 'file')
        save(filepath, 'background', '-append');
    else
        save(filepath, 'background');
    end
end


if exist(filepath, 'file')
    save(filepath, 'flatfields', '-append');
else
    save(filepath, 'flatfields');
end

end

