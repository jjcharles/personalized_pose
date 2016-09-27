%computes hardsegcp feature from rgb input frame
function feat = hardsegcp(opts, rgbimg, patches, seg, bbox)
    
    img = features.segcp(opts,rgbimg,patches,seg);
    
    disk = strel('disk',2);
    [~,channel_id] = max(img,[],3);
    seg_channel = imopen(channel_id==1,disk);
    dist = bwdist(seg_channel);

    N = max(bbox(3:4));
    dist = dist/N;
    dist(dist>1) = 1;
    dist = uint8(255*dist);

    feat = cat(3,uint8(channel_id),dist);