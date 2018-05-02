function proc = pre_process(ims, imdata, makeFlats)

% Flat-field correction
if nargin < 3 || isempty(makeFlats) || ~makeFlats
    m = load('F:\Leo\Background\flatfields.mat');
    for c = 1:size(ims,3)
        channelName = imdata.channels{c};
        flats(:,:,c) = m.flatfields.(channelName);
    end
    ims = batch_flat(ims, flats, m.flatfields.background);
else
    [ims, flats] = batch_flat(ims);
    save('F:\Leo\Background\flatfields-temp.mat', 'flats');
end

% Normalize channels, convert to uint8
fprintf('normalizing channels...\n');
proc = zeros(size(ims),'uint8');
for c = 1:size(ims,3)
    downsampled = ims(1:20:end,1:20:end,c,:);
    lo = double(prctile(downsampled(:),0.1))/double(intmax('uint16'));
    hi = double(prctile(downsampled(:),99.9))/double(intmax('uint16'));
    
    for img = 1:size(ims,4)
        proc(:,:,c,img) = uint8(imadjust(ims(:,:,c,img), ...
            [lo hi], [0 255/double(intmax('uint16'))]));
    end
end
