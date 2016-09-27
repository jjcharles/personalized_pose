function occlusion_model = train_models(opts,videofilename, frameids, locs, labels)
%TRAIN_MODELS Train occlusion models
%   Returns occlusion models for all objects specificed by the label array

    %set maximum number of frames to use for training
    maxframes = 1000;
    
    %normalise joints to sample from, based on head location
    samplelocs = locs;
    remid = samplelocs ==-999;
    offset = bsxfun(@minus,samplelocs,samplelocs(:,1,:));
    samplelocs = samplelocs + offset;
    samplelocs(remid) = -999;
    
    %train model for each input label
    for l = 1:numel(labels)
        %locate non occluded object for this label
        trainids = occlusion.get_non_occlusion(opts,locs,labels(l));
        
        %remove those labels which are not present
        keepid = locs(1,labels(l),:) ~=-999;
        tempframeids = frameids(keepid);
        templocs = locs(:,:,keepid);
        trainids = trainids(keepid);
        
        %limit frames to max if needed
%         idx = round(linspace(1,numel(tempframeids),min([numel(tempframeids),maxframes])));
%         tempframeids = tempframeids(idx);
%         templocs = templocs(:,:,idx);
        if labels(l) == 1
            sampleid = sample_uniformally(squeeze(templocs(:,labels(l),:)),15,1000);
        else
            sampleid = sample_uniformally(squeeze(samplelocs(:,labels(l),keepid)),15,1000);
        end
        trainids = sampleid(trainids(sampleid));
        
         [hog_patches,rgb_patches, training_labels] = occlusion.get_training_patches(opts,videofilename,...
            tempframeids(trainids),squeeze(templocs(:,labels(l),trainids)));
        hog_labels = training_labels;
        rgb_labels = training_labels;
%         
%         %get hog training patches
%         [hog_patches,hog_labels] = occlusion.get_training_patches_hog_v2(opts,videofilename,...
%             tempframeids(trainids),squeeze(templocs(:,labels(l),trainids)));
% 
%         %get rgb training patches
%         [rgb_patches,rgb_labels] = occlusion.get_training_patches_rgb(opts,videofilename,...
%             tempframeids(trainids),squeeze(templocs(:,labels(l),trainids)));

        %train rgb svm
        fprintf('Training RGB occlusion model %d...',labels(l));
        rgbmodel = train_svm_classifier(rgb_labels,rgb_patches,opts.occlusion.sensitivity);
        fprintf('done\n');
        
        %train hog svm
        fprintf('Training HOG occlusion model for label %d...',labels(l));
        hogmodel = train_svm_classifier(hog_labels,hog_patches,opts.occlusion.sensitivity);
        fprintf('done\n');
        
        %store occlusion model
        occlusion_model(l).hogmodel = hogmodel;
        occlusion_model(l).rgbmodel = rgbmodel;
        occlusion_model(l).label = labels(l);
        occlusion_model(l).opts = opts.occlusion;
    end
end

