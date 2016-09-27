%function to get foreground background segmentation from trained detector

function get_background_model(opts,filename,folder,detections_filename,jobid)

if ~exist(filename.patches,'file')
    if jobid == 1
        %load a detector
        model = oforest.load_forest_from_folder(folder.detector);

        %load initial detections
        load(detections_filename);

        prep.get_face_torso_patches(opts,filename.video,model,filename,detections.manual.frameids);
    end
end

setjobcompletion(filename.joblist,jobid);