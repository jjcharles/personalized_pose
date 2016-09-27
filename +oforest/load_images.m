%function to load training images into memory
function [images, labels, sample_idx,total_background, newpadding] = load_images(opts,filename_video, frame_ids, locs)
%images - the training images pluse a few background unlabelled images
%labels - this is actuall the body part locations
%sample_idx - the sample index used to take frames from the training images
%total_background - this is the total number of unlabelled images loaded in
%for using as a negative class
    
    %load in video
    vidobj = VideoReader(filename_video);
    total_background = round(0.05*(vidobj.NumberOfFrames-numel(frame_ids))); %use 5% of remaining frames as background   
    %initialise image set
    total_images = round(opts.model.forest.pertreepercent*numel(frame_ids));
    
    imgwidth = opts.bbox(3) + opts.model.padding*2;
    imgheight = opts.bbox(4) + opts.model.padding*2;
    images = repmat(uint8(0), [imgheight,imgwidth,opts.model.numchannels,total_images+total_background]);

    idrem = locs==-999;
    templocs = bsxfun(@minus,locs,(opts.bbox(1:2)-1)');
    templocs(idrem) = -999;
    %make sure locs are in range
    idrem = (templocs(1,:,:)>imgwidth) | (templocs(2,:,:)>imgheight);
    idrem = cat(1,idrem,idrem);
    locs(idrem) = -999;
            
    fprintf('Loading %d labelled images and %d background images, computing %d rotations and totalling %d training images\n',...
        total_images,total_background,numel(opts.model.rotations),total_images*numel(opts.model.rotations)+total_background);
    labels = zeros(2,opts.model.numclasses-1,total_images);
    
    %uniformaly sample for this image set
    %NOTE: image set was created by sampling from clusters so the set
    %is already diverse in terms of poses
    sample_idx = floor(rand(total_images,1)*numel(frame_ids)+1);
    

    %load in feature representation and build label array
    count = 1;
    datax = opts.bbox(1):(opts.bbox(1) + opts.bbox(3)-1);
    datay = opts.bbox(2):(opts.bbox(2) + opts.bbox(4)-1);
    for i = 1:total_images
        framenumber = frame_ids(sample_idx(i));
        img = imresize(read(vidobj,framenumber),opts.imscale);
        img = img(datay,datax,:);
        img_padded = padarray(img,[opts.model.padding, opts.model.padding, 0],0,'both');
        images(:,:,:,count) = img_padded;
        temp_labels = bsxfun(@minus,locs(:,:,sample_idx(i)),(opts.bbox(1:2)-1)')+opts.model.padding;
        %put -999 label back on joint positions to identify them as having
        %no location for that part
        templocs = locs(:,:,sample_idx(i));
        temp_labels(locs(:,:,sample_idx(i))<0) =   templocs(locs(:,:,sample_idx(i))<0);
        labels(:,:,count) = temp_labels;
        count = count + 1;
    end
    
    R = randperm(vidobj.NumberOfFrames);
    frameids = R(1:total_background);    
    datax = opts.back_bbox(1):(opts.back_bbox(1) + opts.bbox(3)-1);
    datay = opts.back_bbox(2):(opts.back_bbox(2) + opts.bbox(4)-1);
    
    %augment data with rotation
    [images,labels] = oforest.augmentdata(images(:,:,:,1:(count-1)),labels,opts.model.rotations);
    count = size(images,4) + 1;
    images = cat(4,images,repmat(uint8(0),[size(images,1),size(images,2),size(images,3),total_background]));
    
    
    %add on background images
    for i = 1:total_background
        framenumber = frameids(i);
        img = imresize(read(vidobj,framenumber),opts.imscale);
        img = img(datay,datax,:);
        img_padded = padarray(img,[opts.model.padding, opts.model.padding, 0],0,'both');
        images(:,:,:,count) = img_padded;
        count = count + 1;
    end
    
    %add extra padding to images because of data augmentation (calculate
    %optimal padding)
    xval = squeeze(squeeze(labels(1,:,:)));
    xval(xval<0) = [];
    xval = cat(1,xval(:),size(images,2)-xval(:));
    xpad = ceil(opts.model.windowwidth/2)- min(xval) + 1;
    xpad(xpad<1) = 1;
    yval = squeeze(squeeze(labels(2,:,:)));
    yval(yval<0) = [];
    yval = cat(1,yval(:),size(images,1)-yval(:));
    ypad = ceil(opts.model.windowwidth/2)- min(yval) + 1;
    ypad(ypad<1) = 1;
    pad = max(xpad,ypad);
    pad = ceil(pad);
    images = padarray(images,[pad, pad, 0],0,'both');
    labels = labels + pad;
    newpadding = opts.model.padding + pad;
    %round to nearest integer
    labels = round(labels);
    
    
    
end