function updateFlats(flats, channels, background, filepath)
%updateFlats Create a new flatfields structure at the given filepath

flatfields = [];
if exist('background', 'var') && ~isempty(background)
    save(filepath, 'background', '-append');
end

for i = 1:length(channels)
    flatfields.(channels{i}) = flats(:,:,i);
end

save(filepath, 'flatfields', '-append');

end

