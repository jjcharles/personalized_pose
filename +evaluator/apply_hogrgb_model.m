%get lower arm likelihood values by using both a hog and an rgb model
function [detections, removed, fixed] = apply_hogrgb_model(filename,folder,detections,fieldname,hogmodel, rgbmodel,model_scale)
%detections - filtered detections
%removed - ids of where old detections were removed

visualise = false;

frameids = detections.(fieldname).frameids;
locs = detections.(fieldname).locs;
total_frames = numel(frameids);
load(filename.patches);

%load video
vidobj = VideoReader(filename.video);

%load current best model
model = oforest.load_forest_from_folder(folder.detector);
model = oforest.scale_model(model,model_scale);

rgbmodel.opts.template.width = ceil(rgbmodel.opts.shape.width*rgbmodel.opts.shape.scaleval);
rgbmodel.opts.template.height = ceil(rgbmodel.opts.shape.height*rgbmodel.opts.shape.scaleval);
rgbmodel.opts.template.img = zeros(rgbmodel.opts.template.height,rgbmodel.opts.template.width,3,'uint8');

%loop through detections and extract lower arm hog templates
removed = zeros(2,total_frames);
fixed = zeros(2,total_frames);

for i = 1:total_frames
    isleftcorrected = false;
    isrightcorrected = false;
    left_label = 1;
    right_label = 1;
    forestapplied = false;
    
    fprintf('evaluating lower arm RGB/HOG on %s detections, frame %d of %d\n',fieldname,i,total_frames);
    framenumber = frameids(i);
    if (locs(1,3,i)~=-999 || locs(1,2,i)~=-999)
        imgorig = imresize(read(vidobj,framenumber),model.opts.imscale);
        img = imresize(imgorig,model_scale);
    end
    updated_left_locs = locs(:,[3 5],i);
    updated_right_locs = locs(:,[2 4],i);
    if locs(1,3,i)~=-999
        %check elbow exists, if not then generate it with the current
        %forest
        if locs(1,5,i)==-999
            
           templocs = oforest.apply_frame(model,img,[], [], model.opts.bbox, 'rgb', 'slow',ceil(8*model_scale));
           templocs = (templocs)/model_scale;
           locs(:,5,i) = templocs(:,5);
           forestapplied = true;
        end
        
        %classify hog patch
        [left_label,updated_left_locs, isleftcorrected] = classify_patch(imgorig,locs(:,[3 5],i)',hogmodel,rgbmodel,'left');
    end
    
    %check joint location exists for right wrist
    if locs(1,2,i)~=-999
        %check elbow exists, if not then generate it with the current
        %forest
        if locs(1,4,i)==-999
            if forestapplied
                locs(:,4,i) = templocs(:,4);
            else
               templocs = oforest.apply_frame(model,img,[], [], model.opts.bbox, 'rgb', 'slow',ceil(8*model_scale));
               templocs = (templocs)/model_scale;
               locs(:,4,i) = templocs(:,4);
            end
        end
        
        %extract right arm hog patches
        [right_label,updated_right_locs, isrightcorrected] = classify_patch(imgorig,locs(:,[2 4],i)',hogmodel,rgbmodel,'right');       
    end
    
    if visualise
        drawnow
    end
    
    if left_label == 0
        detections.(fieldname).locs(:,[3 5],i) = -999;
        removed(1,i) = 1;
    else
        detections.(fieldname).locs(:,[3 5],i) = updated_left_locs';
        if isleftcorrected
            fixed(1,i) = 1;
        end
    end
    
    if right_label == 0
        detections.(fieldname).locs(:,[2 4],i) = -999;
        removed(2,i) = 1;
    else
        detections.(fieldname).locs(:,[2 4],i) = updated_right_locs';
        if isrightcorrected
            fixed(2,i) = 1;
        end
    end
    
end

%remove redundant frames
remid = sum(sum(detections.(fieldname).locs==-999))==(size(detections.(fieldname).locs,1)*size(detections.(fieldname).locs,2));
detections.(fieldname).locs(:,:,remid) = [];
detections.(fieldname).frameids(remid) =[];
fixed(:,remid) = [];

%function to add hog patch to append hog patch to the training set
    function [label,templocs,iscorrected] = classify_patch(img,locs,hogmodel,rgbmodel,mode)
        iscorrected = false;
        switch lower(mode)
            case 'left'
                hogshape = hogmodel.left_shape;
                rgbshape = rgbmodel.left_shape;
            case 'right'
                hogshape = hogmodel.right_shape;
                rgbshape = rgbmodel.right_shape;
            otherwise 
                error('mode unknown in evaluate_patch')
        end
        
        numjitters = 10;
        [M,N,~] = size(img);
        bestdecision = -inf;
        for n = 1:numjitters
            if n== 1
                templocs = locs;
            else
                templocs = locs + randn(size(locs))*3;
            end
            templocs(templocs(:,1)<1,1) = 1;
            templocs(templocs(:,1)>N,1) = N;
            templocs(templocs(:,2)<1,1) = 1;
            templocs(templocs(:,2)>M,1) = M;
            can_patch = shape.img2can(img,templocs(:,1),templocs(:,2),hogmodel.opts.shape.anchor,hogmodel.opts.evaluator.hog.shape.width,hogmodel.opts.evaluator.hog.shape.height,'rgb');
            

            hogpatch = single(features.hog(can_patch,hogmodel.opts.evaluator.hog.cellsize));
            hogpatch = sparse(double(hogpatch(:)'));
            [~, ~, decision_hog] = predict_linsvm(0,hogpatch, hogshape.svmmodel,'-q');
            labelhog = decision_hog > hogshape.thresh;

            can_patch = shape.img2can(img,templocs(:,1),templocs(:,2),rgbmodel.opts.shape.anchor,rgbmodel.opts.shape.width,rgbmodel.opts.shape.height,'rgb');
            can_patch = imresize(can_patch, [rgbmodel.opts.template.height, rgbmodel.opts.template.width]);
            
            can_patch = sparse(double(can_patch(:)'));
            [~,~,decision_rgb] = predict_linsvm(0,can_patch, rgbshape.svmmodel,'-q');
            labelrgb = decision_rgb > rgbshape.thresh;            
            label = logical(labelhog) && logical(labelrgb);

            if label == 1
                if n > 1
                    iscorrected = true;
                end
                break
            end
            
        end
        
        
