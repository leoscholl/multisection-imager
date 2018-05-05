function transforms = registerSeries(img, metadata, rois)

downsample = 10;
fixed = stitchImg(img, metadata, downsample, rois(1,:));
fixed = medfilt2(fixed, [10 10]);
msg = '';
for n = 2:size(rois,1)
    
    fprintf(repmat('\b',1,length(msg)));
    msg = sprintf('registering image %d/%d', n, size(rois,1));
    fprintf(msg)

    moving = stitchImg(img, metadata, downsample, rois(n,:));
    moving = medfilt2(moving, [10 10]);
    
    [optimizer, metric] = imregconfig('monomodal');
    transforms{n} = imregtform(moving, fixed,...
        'rigid', optimizer, metric);
    est = imwarp(moving,transforms{n},'OutputView',imref2d(size(fixed)));
    
    [transforms{n},fixed_] = imregdemons(est,fixed);

    imshowpair(est,fixed_)
    
end
fprintf('\n');