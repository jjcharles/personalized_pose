%function to train occlusion detector on HPC
function train_occlusion_detector(opts,filename,folder,detections,fieldname,tag,jobid,maxjobs)

    folder.occlusiondetector = check_dir(sprintf('%socclusion_detectors',folder.model),true);
    filename.occlusiondetector = sprintf('%socclusion_detector_%s.mat',folder.occlusiondetector,tag);
    
    if jobid == 1
        if ~exist(filename.occlusiondetector,'file')
            %train the occlusion model
            occlusion_model = occlusion.train_models(opts,filename.video, detections.(fieldname).frameids, detections.(fieldname).locs, opts.occlusion.detection_labels);
            save(filename.occlusiondetector,'occlusion_model');
        end
    end
    setjobcompletion(filename.joblist,jobid);
    waitforalljobs(filename,maxjobs);

        