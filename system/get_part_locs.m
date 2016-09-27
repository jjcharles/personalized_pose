%function to return part locations splitting the job over multiple clusters

function detections = get_part_locs(opts,filename,folder_detector,folder_cache,model_scale,jobid,maxjobs)
%model_scale is the amount by which we wish to scale the image size so the
%model runs faster when detecting proposals

    if model_scale > 1 || model_scale <= 0
        error('model_scale needs to be less than 1 and greater than 0')
    end
    
    if ~exist(folder_cache,'dir'); mkdir(folder_cache); end
    
    if ~exist(sprintf('%sbodypose.mat',folder_cache),'file')
        model = oforest.load_forest_from_folder(folder_detector);
        model = oforest.scale_model(model,model_scale);
        
        vidobj = VideoReader(filename.video);
        
        %load in current detections
        current_detections = load(filename.detections);

        %find frames where we have no good manual
        if isfield(current_detections.detections,'manual')
            isgood = sum(sum(current_detections.detections.manual.locs~=-999))==(size(current_detections.detections.manual.locs,1)*size(current_detections.detections.manual.locs,2));
            goodframeids = unique(current_detections.detections.manual.frameids(isgood));
        else
            goodframeids = [];
        end
        
        allframeids = 1:vidobj.NumberOfFrames;
        allframeids(goodframeids) = [];
        
        %uniformally select frames from the video according to a set step size
        ridx = allframeids(1:opts.flow.numneighbours:end);

        %split up jobs
        split = repmat(floor(numel(ridx)/(maxjobs)),1,maxjobs);
        split(end) = split(1) + rem(numel(ridx),maxjobs);
        split = [1, split];
        split = cumsum(split);
        from = split(jobid);
        to = split(jobid+1)-1;

        %frames
        frameids = ridx(from:to);

        total_frames = numel(frameids);
        filename.bodypart_temp = sprintf('%sbodypose_temp_jobid_%03d.mat',folder_cache,jobid);
        if ~exist(filename.bodypart_temp,'file')
            locs = zeros(2,model.opts.model.numclasses-1,total_frames);
            confidence = zeros(total_frames,model.opts.model.numclasses-1);
            fprintf('Obtaining body part locations...');
            nextperc = 25;
            for i = 1:total_frames
                fprintf('frame %d of %d\n',i,total_frames);
                framenumber = frameids(i);
                img = imresize(read(vidobj,framenumber),model.opts.imscale*model_scale);
                [pose,~,conf] = oforest.apply_frame(model,img,[],[],model.opts.bbox,'rgb','slow',ceil(8*model_scale));
                confidence(i,:) = conf;
                locs(:,:,i) = (pose-1)/model_scale + 1;
                if floor(i/total_frames*100)>=nextperc
                    fprintf('%d%%...',round(i/total_frames*100));
                    nextperc = nextperc + 25;
                end
            end

            %save the temporary detections
            save(filename.bodypart_temp,'locs','confidence','frameids');
            fprintf('done\n')
        end

        %compile all once complete
        if jobid==maxjobs
            waitforremainingjobs(filename,maxjobs)
            locs = [];
            confidence = [];
            frameids = [];
            for i = 1:maxjobs
                tempdata = load(sprintf('%sbodypose_temp_jobid_%03d.mat',folder_cache,i));
                locs = cat(3,locs,tempdata.locs);
                confidence = cat(1,confidence,tempdata.confidence);
                frameids = cat(2,frameids,tempdata.frameids);
            end

            %save the body part locations
            save(sprintf('%sbodypose.mat',folder_cache),'locs','confidence','frameids');
        
            %load in current detections
            load(filename.detections);

            detections.group.locs = locs;
            detections.group.frameids = frameids;
            detections.group.conf = confidence;

            %save
            save(filename.detections,'detections');
        end
    end

    %set completion tag in jobfile
    setjobcompletion(filename.joblist,jobid);
    waitforalljobs(filename,maxjobs);
    load(filename.detections);
    
    
    
        
    
    