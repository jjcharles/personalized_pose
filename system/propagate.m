function detections = propagate(videoname,dataset,initial_det_file,maxitr,jobid,maxjobs)
%PROPAGATE propagte poses throughout an input video
%   Propagates initial human pose estimates throughout a video based on the
%   methods described in [1]. See demo.m for example usage.
%
%   [1] Charles, J. and Pfister, T. and Magee, D. and Hogg, D. and Zisserman, A.
%   Personalizing Human Video Pose Estimation, CVPR 2016
%
%   ---- INPUTS ----
%   vidoename - name of input video
%   dataset - name of dataset, (default 'youtube')
%   initial_det_file - filename to initial detections
%   maxitr - maximum number of propagation iterations
%   jobid - cpu/job number if distributing (default 1)
%   maxjobs - max number of cpus for distribution (default 1)
%
%   ---- OUTPUT ----
%   detections - struct containing propagated body joint locations

if ischar(jobid); jobid = str2double(jobid); end
if ischar(maxjobs); maxjobs = str2double(maxjobs); end

%load options
[opts,folder] = load_system_options(dataset,videoname);

%setup filenames and folders
[filename,folder] = setup_filenames(folder, videoname, dataset);

%get initial detections
filename.saved_initial_detections = initial_det_file;
load(filename.saved_initial_detections);

%check initialisation
if ~exist('detections','var')
    error('no initial detections available')
end

if ~isfield(detections,'manual')
    error('detections struct should have a field called manual to start')
end

if ~isfield(detections.manual,'locs')
    error('detections.manual should have a field called locs to start')
end

if ~isfield(detections.manual,'frameids')
    error('detections.manual should have a field called frameids to start')
end

if isempty(detections.manual.frameids);
    error('no initial frames to start with so exiting');
end

if isempty(detections.manual.locs); 
    error('no initial detections to start with so exiting');
end

%set iteration counter
itr = 1;

%get clustered training
filename = setupwaiting(filename, folder, jobid, maxjobs,'getting_initial_training_detections');
traindet = get_training_detections_annotation(folder,filename,detections,'initial_training',jobid,maxjobs); 
load(filename.detections);

%train an initial part detector
filename = setupwaiting(filename,folder,jobid,maxjobs,'initial_detector');
folder.detector = sprintf('%s/initial_detector/',folder.model);
initialtreedepth = 24;
train_detector_tree(opts,filename,folder,initialtreedepth,jobid,maxjobs,traindet.training.frameids,traindet.training.locs);
waitforalljobs(filename,maxjobs);

%get temporary background model 
filename.patches = sprintf('%svideoToColorprogramme_%s_v1.mat',folder.cache,videoname);
filename = setupwaiting(filename,folder,jobid,maxjobs,'background_model_1');
get_background_model(opts,filename,folder,filename.saved_initial_detections,jobid);
waitforalljobs(filename,maxjobs);

%train lower arm evaluator
filename = setupwaiting(filename, folder, jobid, maxjobs,'training_evaluator_initial');
train_lower_arm_evaluator(opts,filename,folder,'training','initial_evaluator',jobid);
waitforalljobs(filename,maxjobs);

%run evaluator
filename = setupwaiting(filename, folder, jobid, maxjobs,sprintf('evaluating_manual_joints_%02d',itr));
f_b_evaluation_hpc(opts,filename,folder,'manual','initial_evaluator',jobid,maxjobs);
waitforalljobs(filename,maxjobs);
load(filename.detections);

%get clustered training data
filename = setupwaiting(filename, folder, jobid, maxjobs,'getting_initial_training_detections_v2');
load(filename.detections);
traindet = get_training_detections_annotation(folder,filename,detections,'initial_training_v2',jobid,maxjobs); 
load(filename.detections);  

%retrain part detector on evaluated initialisation
filename = setupwaiting(filename,folder,jobid,maxjobs,'retrained_initial_detector');
folder.detector = sprintf('%s/detector_itr_%02d/',folder.model,itr);
initialtreedepth = 64;
train_detector_tree(opts,filename,folder,initialtreedepth,jobid,maxjobs,traindet.training.frameids,traindet.training.locs);
%wait for all jobs
waitforalljobs(filename,maxjobs);

%reproduce background model 
filename.patches = sprintf('%svideoToColorprogramme_%s_v2.mat',folder.cache,videoname);
filename = setupwaiting(filename,folder,jobid,maxjobs,'background_model_2');
get_background_model(opts,filename,folder,filename.detections,jobid);
waitforalljobs(filename,maxjobs);

for itr = 1:maxitr
    %get clustered manuals - for matching parts
    filename = setupwaiting(filename, folder, jobid, maxjobs,sprintf('getting_clustered_manuals_itr_%02d',itr));
    detections = get_clustered_manuals(opts,filename,detections,'rgb_attenuated',jobid,maxjobs);
    
    %perform spatial matching (only one round was found necessary)
    for numroundclustering = 1:1
        filename.clusters = sprintf('%sclusteredparts_itr_%02d_round_%02d.mat',folder.cache,itr,numroundclustering);
        filename.unrefined_clusters = sprintf('%sunrefined_clusteredparts_itr_%02d_round_%02d.mat',folder.cache,itr,numroundclustering);
        cluster_folder = sprintf('%sall_clustered_patches_itr_%02d_round_%02d/',folder.model,itr,numroundclustering);

        %get body part proposals
        filename = setupwaiting(filename, folder, jobid, maxjobs,sprintf('pose_detection_itr_%02d_round_%02d',itr,numroundclustering));
        get_part_locs(opts,filename,folder.detector,cluster_folder,opts.partdetector.model.modelscale,jobid,maxjobs); %runs at half image resolution for speed
        load(filename.detections);
        
        %get training data for training an arm evaluator
        filename = setupwaiting(filename, folder, jobid, maxjobs,sprintf('getting_training_data_itr_%02d',itr));
        get_training_detections_annotation(folder,filename,detections,sprintf('training_data_itr_%02d',itr),jobid,maxjobs); 
        load(filename.detections);
        
        %train evaluator
        filename = setupwaiting(filename, folder, jobid, maxjobs,sprintf('training_evaluator_itr_%02d',itr));
        train_lower_arm_evaluator(opts,filename,folder,'training',sprintf('evaluator_itr_%02d',itr),jobid);
        waitforalljobs(filename,maxjobs);
        
        %run evaluator
        filename = setupwaiting(filename, folder, jobid, maxjobs,sprintf('evaluating_proposed_joints_%02d',itr));
        f_b_evaluation_hpc(opts,filename,folder,'group',sprintf('evaluator_itr_%02d',itr),jobid,maxjobs);
        waitforalljobs(filename,maxjobs);
        load(filename.detections);
    
        %get part patch proposals which pass the evaluator
        filename = setupwaiting(filename, folder, jobid, maxjobs,sprintf('extracting_parts_itr_%02d_round_%02d',itr,numroundclustering));
        get_part_proposals_hpc(opts,filename,detections,jobid,maxjobs,cluster_folder); %saves them to disk
        waitforalljobs(filename,maxjobs);
        
        %perform the matching 
        filename = setupwaiting(filename, folder, jobid, maxjobs,sprintf('clustering_itr_%02d_round_%02d',itr,numroundclustering));
        if jobid==1
            match_body_parts(opts,filename,folder.detector,cluster_folder,detections,maxjobs);
        end
        waitforalljobs(filename,maxjobs);
        
        %propagate the patch label with siftflow
        %apply_siftflow - computes energy term but flow itself is switched off
        filename = setupwaiting(filename, folder, jobid, maxjobs,sprintf('siftflow_itr_%02d_round_%02d',itr,numroundclustering));
        apply_siftflow(filename,folder,jobid,maxjobs,itr);
        waitforalljobs(filename,maxjobs);
        load(filename.detections);
    end

    %use optical flow to propergate joints temporaly
    filename = setupwaiting(filename, folder, jobid, maxjobs,sprintf('temporal_flow_%02d',itr));
    temporal_propergation(opts,filename,folder,jobid,maxjobs,itr);
    waitforalljobs(filename,maxjobs);

    %run a foreground/background evaluator
    filename = setupwaiting(filename, folder, jobid, maxjobs,sprintf('evaluating_temporal_propagation_%02d',itr));
    f_b_evaluation_hpc(opts,filename,folder,'annotation',sprintf('evaluator_itr_%02d',itr),jobid,maxjobs);
    waitforalljobs(filename,maxjobs);
    
    %train the occlusion detector for head, shoulders and elbows
    load(filename.detections);
    filename = setupwaiting(filename, folder, jobid, maxjobs,sprintf('train_occlusion_detector_%02d',itr));
    train_occlusion_detector(opts,filename,folder,detections,'manual',sprintf('itr_%02d',itr),jobid,maxjobs)
    
    %run the occlusion detector on head, shoulders and elbows
    filename = setupwaiting(filename, folder, jobid, maxjobs,sprintf('run_occlusion_detector_%02d',itr));
    apply_occlusion_detection(opts,filename,folder,'annotation',sprintf('itr_%02d',itr),jobid,maxjobs);

    %add new ground truth frames to detections and repeat above
    load(filename.detections);
    filename = setupwaiting(filename, folder, jobid, maxjobs,sprintf('getting_new_detections_%02d',itr));
    filename.detections = sprintf('%sdetections_itr_%02d.mat',folder.model,itr+1);
    update_initial_detections(filename,detections,15,filename.detections,jobid,maxjobs);
    waitforalljobs(filename,maxjobs);
    
    %retrain a part detector if we are going to repeat
    if itr<maxitr
        %get training data
        filename = setupwaiting(filename, folder, jobid, maxjobs,sprintf('getting_training_detections_itr_%02d',itr+1));
        load(filename.detections);
        traindet = get_training_detections_annotation(folder,filename,detections,sprintf('iteration_%02d',itr+1),jobid,maxjobs); 
        load(filename.detections);
        
        %train detector
        filename = setupwaiting(filename, folder, jobid, maxjobs,sprintf('part_detector_itr_%02d',itr+1));
        folder.detector = sprintf('%s/detector_itr_%02d/',folder.model,itr+1);
        stage1treedepth = initialtreedepth;
        train_detector_tree(opts,filename,folder,stage1treedepth,jobid,maxjobs,traindet.training.frameids,traindet.training.locs);
        waitforalljobs(filename,maxjobs);
    end
end
load(filename.detections);
