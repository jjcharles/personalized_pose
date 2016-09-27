%function to perform foreground background detection evaluation on the
%cluster.
%uses svm trained lower arm evaluators where the thresholds were
%learnt on a hold-out validation set - also runs over multiple jobs
function f_b_evaluation_hpc(opts,filename,folder,fieldname,evaluator_id,jobid,maxjobs)
%evaluator_id is a string which identifies the evaluation
load(filename.detections);

runevaluation = false;
if isfield(detections.(fieldname),'is_evaluated')
    if detections.(fieldname).is_evaluated==false;
        runevaluation = true;
    end
else
    runevaluation = true;
end

if runevaluation
    
    evaluator_folder = check_dir(sprintf('%sevaluation_%s/',folder.model,evaluator_id),true);
    filename.lowerarmmodel = sprintf('%slower_arm_shape.mat',evaluator_folder);
    filename.temp_evaled_detections = sprintf('%sdetections_temp_%02d.mat',evaluator_folder,jobid);
    alldetections = detections;
    
    %split job over nodes
    split = repmat(floor(numel(detections.(fieldname).frameids)/(maxjobs)),1,maxjobs);
    split(end) = split(1) + rem(numel(detections.(fieldname).frameids),maxjobs);
    split = [1, split];
    split = cumsum(split);
    from = split(jobid);
    to = split(jobid+1)-1;


    detections.(fieldname).frameids = detections.(fieldname).frameids(from:to);
    detections.(fieldname).locs = detections.(fieldname).locs(:,:,from:to);

    %load lower arm models
    load(filename.lowerarmmodel);

    %evaluate
    detections = evaluator.foreground_background_eval(opts,filename,alldetections,detections,fieldname);
    detections = evaluator.apply_hogrgb_model(filename,folder,detections,fieldname,hogmodel,rgbmodel,0.25);
    save(filename.temp_evaled_detections,'detections');
    
    if jobid == maxjobs
        waitforremainingjobs(filename,maxjobs);
        detections = alldetections; %reset to original detections
        detections.(fieldname).locs = [];
        detections.(fieldname).frameids = [];
        
        %collect evaluated detections
        for j = 1:maxjobs
            filename.temp_evaled_detections = sprintf('%sdetections_temp_%02d.mat',evaluator_folder,j);
            tempdets = load(filename.temp_evaled_detections);
            detections.(fieldname).locs = cat(3,detections.(fieldname).locs,tempdets.detections.(fieldname).locs);
            detections.(fieldname).frameids = cat(2,detections.(fieldname).frameids,tempdets.detections.(fieldname).frameids);
        end
        detections.(fieldname).is_evaluated = true;
        
        %check that we have at least 1 frame from each joint 
        for l = 1:size(detections.(fieldname).locs)
            numframes = sum(detections.(fieldname).locs(1,l,:)~=-999);
            if numframes == 0
                %add manuals back for this joint (what else can we do?)
                id = find(detections.manual.locs(1,l,:)~=-999);
                locs = detections.manual.locs(:,l,id);
                frameids = detections.manual.frameids(id);
                ia = ismember(detections.(fieldname).frameids,frameids);
                if isempty(ia)
                    %just append
                    locsblank = -999*ones(2,size(detections.(fieldname).locs,2),size(locs,3));
                    locsblank(:,l,:) = locs;
                    detections.(fieldname).locs = cat(3,detections.(fieldname).locs,locsblank);
                    detections.(fieldname).frameids = cat(2,detections.(fieldname).frameids,frameids);
                else
                    addid = find(ia);
                    for j = 1:numel(addid)
                        detections.(fieldname).locs(:,l,addid(j)) = locs(:,:,j);
                    end
                end
            end
        end

        %reorder frame ascending
        [frameids,srtid] = sort(detections.(fieldname).frameids);
        detections.(fieldname).locs = detections.(fieldname).locs(:,:,srtid);
        detections.(fieldname).frameids = frameids; 

        save(filename.detections,'detections');
    end
end

setjobcompletion(filename.joblist,jobid);
