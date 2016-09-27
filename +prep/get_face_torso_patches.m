%function to get the face and torso patches
function videoToColor = get_face_torso_patches(opts,videofilename,model,filename,frameids)
    vidobj = VideoReader(videofilename);
    if ~exist('frameids','var');
        frameids = 1:20:vidobj.NumberOfFrames;
    end

    videoToColor = [];
    
    frameids = frameids(round(linspace(1,numel(frameids),min(numel(frameids),opts.background.maxframes))));
    [locs,confout,dist] = oforest.apply_video(model,videofilename,frameids,opts.partdetector.model.modelscale);
    
    bestid = find(confout(:,1)>0.01);
    
    if isempty(bestid)
        bestid = 1:numel(frameids);
    end
    %find good background patches
    
    se = strel('disk',5);
    
    for i = 1:numel(bestid)
        datax = model.opts.bbox(1):(model.opts.bbox(1)+model.opts.bbox(3)-1);
        datay = model.opts.bbox(2):(model.opts.bbox(2)+model.opts.bbox(4)-1);
        torsoheight = round(squeeze(sqrt(sum((locs(:,4,i)-locs(:,2,i)).^2)) + sqrt(sum((locs(:,4,i)-locs(:,6,i)).^2))));
        torsowidth = round(squeeze(sqrt(sum(locs(:,6,i)-locs(:,7,i)).^2)));
        facewidth = torsowidth/2;
        idx = bestid(i);
        img = imresize(read(vidobj,frameids(idx)),model.opts.imscale);
        videoToColor{i}.face = imcrop(img,[(locs(:,1,idx)' - ceil(facewidth/2)) facewidth facewidth]);
        torsotopleft = round(mean(locs(:,[6,7],i),2));
        torsotopleft(1) = torsotopleft(1) -ceil(torsowidth/2);
        torsobbox = [torsotopleft' torsowidth torsoheight];
        videoToColor{i}.torso = imcrop(img,torsobbox);
        videoToColor{i}.torsoMask = ones(size(videoToColor{i}.torso,1),size(videoToColor{i}.torso,2));
        videoToColor{i}.back = img(datay,datax,:);
        backconf = sum(dist(:,:,1:(end-1),i),3);
        backconf = backconf/max(backconf(:));
        thresh = graythresh(backconf);
        videoToColor{i}.backmask = imerode(backconf> thresh,se);
        torsobbox(1:2) = torsobbox(1:2)-model.opts.bbox(1:2) + 1;
        if torsobbox(1)<1; torsobbox(1)=1; end
        if torsobbox(2)<1; torsobbox(2)=1; end
        if (torsobbox(1)+torsobbox(3)-1) > size(img,2); torsobbox(3) = size(img,2)-torsobbox(1); end
        if (torsobbox(2)+torsobbox(4)-1) > size(img,1); torsobbox(4) = size(img,1)-torsobbox(2); end
        datax = torsobbox(1):(torsobbox(1)+torsobbox(3)-1);
        datax(datax>model.opts.bbox(3)) = model.opts.bbox(3);
        
        datay = torsobbox(2):(torsobbox(2)+torsobbox(4)-1);
        datay(datay>model.opts.bbox(4)) = model.opts.bbox(4);
        
        videoToColor{i}.backmask(datay,datax) = 1;
        videoToColor{i}.backmask = ~logical(videoToColor{i}.backmask);
        if numel(videoToColor{i}.backmask)~=size(videoToColor{i}.back,2)*size(videoToColor{i}.back,1); keyboard; end
    end
    
    [feat,colourhist] = features.cp(opts,img,videoToColor);
    videoToColor{1}.colourhist= colourhist;
    %now we have histogram remove the other fields
    videoToColor(2:end) = [];
    videoToColor = {rmfield(videoToColor{1},{'torso','face','torsoMask','backmask','back'})};
        
    save(filename.patches,'videoToColor')
    