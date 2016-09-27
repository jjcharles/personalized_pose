%function to perform foreground background detection evaluation on the
%cluster
function train_lower_arm_evaluator(opts,filename,folder,fieldname,evaluator_id,jobid)
%evaluator_id is a string which identifies the evaluation
load(filename.detections);

%runevaluation
if jobid == 1
    evaluator_folder = check_dir(sprintf('%sevaluation_%s/',folder.model,evaluator_id),true);
    filename.temp_evaled_detections = sprintf('%sdetections_temp_%02d.mat',evaluator_folder,jobid);
    filename.lowerarmmodel = sprintf('%slower_arm_shape.mat',evaluator_folder);

    if ~exist(filename.lowerarmmodel,'file')
        [hogmodel, rgbmodel] = evaluator.get_hogrgb_models(opts,filename,folder,detections,fieldname,0.25);
        save(filename.lowerarmmodel,'hogmodel','rgbmodel');
    end
end

setjobcompletion(filename.joblist,jobid);
