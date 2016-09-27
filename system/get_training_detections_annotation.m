%function to form clustered manuals
% uses a pose sampler rather than clustering patches
%uses a tag to save the detections
%allows for each tree to sample its own training data
function detections = get_training_detections_annotation(folder,filename,detections,tag,jobid,maxjobs)
temptrain_folder = check_dir(sprintf('%stemp_training',folder.model),true);
filename.temptraining = sprintf('%s%s_jobid_%02d.mat',temptrain_folder,tag,jobid);
    
if ~exist(filename.temptraining,'file')
    fprintf('Getting training detections from manuals...\n');
    tempdetections = evaluator.sample_detections(detections,'manual',25,1500);

    detections.training.frameids = tempdetections.sampled.frameids;
    detections.training.locs = tempdetections.sampled.locs;
    fprintf('done\n');
    save(filename.temptraining,'detections');
%     save(filename.detections,'detections');
    if jobid == 1
        waitforremainingjobs(filename,maxjobs);
        save(filename.detections,'detections');
    end
end


setjobcompletion(filename.joblist,jobid);
waitforalljobs(filename,maxjobs);
load(filename.temptraining);
