%function to apply partdetector to video
function [locs,confout,dist] = apply_video(omodel,videofilename,frameids,model_scale)
orig_bbox = omodel.opts.bbox;
if ~exist('model_scale','var')
    model_scale = 1;
else
    
    omodel = oforest.scale_model(omodel,model_scale);
end

vidobj = VideoReader(videofilename);

locs = zeros(2,omodel.opts.model.numclasses-1,numel(frameids));
confout = zeros(numel(frameids),omodel.opts.model.numclasses-1);
count = 1;

if nargout  == 3
    dist = zeros(orig_bbox(4),orig_bbox(3),omodel.opts.model.numclasses,numel(frameids),'uint8');
end

for i = frameids 
    fprintf('Estimating pose for frame %d of %d\n',count,numel(frameids));
    img = imresize(read(vidobj,i),omodel.opts.imscale*model_scale);
    bbox = [1 1 size(img,2),size(img,1)];
    [l,tempdist,conf,~] = oforest.apply_frame(omodel,img,[],[],omodel.opts.bbox,'rgb','slow',ceil(8*model_scale)); 
    if model_scale ~= 1
        dist(:,:,:,count) = imresize(uint8(255*tempdist),[orig_bbox(4),orig_bbox(3)]);
    else
        dist(:,:,:,count) = uint8(255*tempdist);
    end
    
    l = l/model_scale;
    l(l==0) = 1;
    locs(:,:,count) = l;
    confout(count,:) = conf;
    count = count +1;
end

    