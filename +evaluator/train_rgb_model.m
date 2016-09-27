%get lower arm likelihood values
%leaves a hold out validation set to tune confidence values
function [left_shape,right_shape] = train_rgb_model(opts,filename,folder,detections,fieldname,model_scale)

visualise = false;

frameids = detections.(fieldname).frameids;
locs = detections.(fieldname).locs;
total_frames = numel(frameids);
load(filename.patches);
neg_samplewidth = 80;

%load video
vidobj = VideoReader(filename.video);

%load current best model
model = oforest.load_forest_from_folder(folder.detector);
model = oforest.scale_model(model,model_scale);
opts.scaleval = 1/3;
opts.shape.width = opts.shape.width; %use twise the width than for the RGB templates
opts.template.width = ceil(opts.shape.width*opts.scaleval);
opts.template.height = ceil(opts.shape.height*opts.scaleval);
opts.template.img = zeros(opts.template.height,opts.template.width,3,'uint8');

    
if visualise
    figure(100);
    subplot(1,2,1)
    h_img_left = imagesc(opts.template.img);
    colormap gray
    subplot(1,2,2)
    h_img_right = imagesc(opts.template.img);
    colormap gray
end
num_negperframe = 5;
len_data = opts.template.width*opts.template.height*3;
total_train = num_negperframe*total_frames + total_frames;

%setup shape models
left_shape.count = 1;
left_shape.svmmodel = [];
left_shape.label = ones(total_train,1);
left_shape.traindata = repmat(single(0),[total_train,len_data]);

right_shape.count = 1;
right_shape.svmmodel = [];
right_shape.label = ones(total_train,1);
right_shape.traindata = repmat(single(0),[total_train,len_data]);


%loop through manual detections and extract lower arm hog templates
for i = 1:total_frames
    forestapplied = false;
    
    fprintf('training lower arm SVM RGB evaluator on %s detections, frame %d of %d\n',fieldname,i,total_frames);
    framenumber = frameids(i);
    if (locs(1,3,i)~=-999 || locs(1,2,i)~=-999)
        imgorig = imresize(read(vidobj,framenumber),model.opts.imscale);
        img = imresize(imgorig,model_scale);
    end
    
    if locs(1,3,i)~=-999
        %check elbow exists, if not then generate it with the current
        %forest
        if locs(1,5,i)==-999
           templocs = oforest.apply_frame(model,img,[], [], model.opts.bbox, 'rgb', 'slow',ceil(8*model_scale));
           templocs = (templocs-1)/model_scale + 1;
           locs(:,5,i) = templocs(:,5);
           forestapplied = true;
        end
        
        %append training hog patch
        left_shape = append_patch(opts,imgorig,locs(:,[3 5],i)',left_shape,1);%use a positive label (1)        
        
        %generate negatives 
        %include the right hand swap
        if locs(1,2,i)~=-999
            left_shape = append_patch(opts,imgorig,locs(:,[2 5],i)',left_shape,0); %use a negative label (0)   
            left_shape = get_negatives(opts,imgorig,locs(:,[3 5],i)',left_shape,num_negperframe-1,neg_samplewidth);
        else
            left_shape = get_negatives(opts,imgorig,locs(:,[3 5],i)',left_shape,num_negperframe,neg_samplewidth);
        end
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
               templocs = (templocs-1)/model_scale + 1;
               locs(:,4,i) = templocs(:,4);
            end
        end
        
        %extract right arm hog patches
        right_shape = append_patch(opts,imgorig,locs(:,[2 4],i)',right_shape,1);%use a positive label (1)        
        
        %generate negatives
        %include the left hand swap
        if locs(1,3,i)~=-999
            right_shape = append_patch(opts,imgorig,locs(:,[3 4],i)',right_shape,0); %use a negative label (0)   
            right_shape = get_negatives(opts,imgorig,locs(:,[2 4],i)',right_shape,num_negperframe-1,neg_samplewidth);
        else
            right_shape = get_negatives(opts,imgorig,locs(:,[2 4],i)',right_shape,num_negperframe,neg_samplewidth);
        end
    end
    
    if visualise
        avg_left_hog = mean(single(left_shape.traindata(left_shape.label(1:(left_shape.count-1))==1,:)),1);
        avg_left_hog = reshape(avg_left_hog,[opts.template.height,opts.template.width,32]);
        avg_left_hog_img = showHOG(avg_left_hog);
        
        avg_right_hog = mean(single(right_shape.traindata(right_shape.label(1:(right_shape.count-1))==1,:)),1);
        avg_right_hog = reshape(avg_right_hog,[opts.template.height,opts.template.width,32]);
        avg_right_hog_img = showHOG(avg_right_hog);
        
        set(h_img_left,'cdata',avg_left_hog_img);
        set(h_img_right,'cdata',avg_right_hog_img);
        drawnow
    end
end

%clean up the models
left_shape = clean_model(left_shape);
right_shape = clean_model(right_shape);

%train the SVM classifier for left arm
fprintf('Training the left SVM...\n');
[svmmodel, best_thresh] = train_svm_classifier(left_shape.label,left_shape.traindata,0.98);
left_shape.svmmodel = svmmodel;
left_shape.thresh = best_thresh;
left_shape = rmfield(left_shape,'label');
left_shape = rmfield(left_shape,'traindata');

fprintf('Training the right SVM...\n');
[svmmodel, best_thresh] = train_svm_classifier(right_shape.label,right_shape.traindata,0.98);
right_shape.svmmodel = svmmodel;
right_shape.thresh = best_thresh;
right_shape = rmfield(right_shape,'label');
right_shape = rmfield(right_shape,'traindata');

%function to add hog patch to append hog patch to the training set
    function shape_model = append_patch(opts,img,locs,shape_model,label)
        can_patch = shape.img2can(img,locs(:,1),locs(:,2),opts.shape.anchor,opts.shape.width,opts.shape.height,'rgb');
        can_patch = imresize(can_patch, [opts.template.height, opts.template.width]);
        shape_model.traindata(shape_model.count,:) = can_patch(:)';
        shape_model.label(shape_model.count) = label;
        shape_model.count = shape_model.count + 1;
        
%function to grab negative patches from an image
    function shape_model = get_negatives(opts,img,locs,shape_model,numnegs,neg_samplewidth)
        padding = 20;
        [M,N,~] = size(img);
        for n = 1:numnegs
            %get patch distorted from wrist
            randx = floor(rand*neg_samplewidth) + 1 + locs(1,1)-ceil(neg_samplewidth/2);
            randy = floor(rand*neg_samplewidth) + 1 + locs(1,2)-ceil(neg_samplewidth/2);
            randx(randx<locs(1,1)) = randx - padding;
            randx(randx>=locs(1,1)) = randx + padding;
            randy(randy<locs(1,2)) = randy - padding;
            randy(randy>=locs(1,2)) = randy + padding;
            
            randx(randx<1) = 1;
            randy(randy<1) = 1;
            randx(randx>N) = N;
            randy(randy>M) = M;
            templocs = [[randx,randy];locs(2,:)];
            shape_model = append_patch(opts,img,templocs,shape_model,0); %use a negative label (0)    
            
            %get patch distorted from elbow
            randx = floor(rand*neg_samplewidth) + 1 + locs(2,1)-ceil(neg_samplewidth/2);
            randy = floor(rand*neg_samplewidth) + 1 + locs(2,2)-ceil(neg_samplewidth/2);
            randx(randx<locs(2,1)) = randx - padding;
            randx(randx>=locs(2,1)) = randx + padding;
            randy(randy<locs(2,2)) = randy - padding;
            randy(randy>=locs(2,2)) = randy + padding;
            
            randx(randx<1) = 1;
            randy(randy<1) = 1;
            randx(randx>N) = N;
            randy(randy>M) = M;
            templocs = [locs(1,:);[randx,randy]];
            shape_model = append_patch(opts,img,templocs,shape_model,0); %use a negative label (0)    
        end

%function to clean up the models
        function shape_model = clean_model(shape_model)
            shape_model.traindata(shape_model.count:end,:) = [];
            shape_model.label(shape_model.count:end) = [];
            

            
            