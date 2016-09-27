%TRAIN_FOREST - trains a part detector classifier for object locations
%implementation to run on cluster
function tree = train_forest_cluster(opts,filenames,frame_ids,locs,treeid)

    fprintf('Training part detectors (%d images):...',numel(frame_ids));

    rseed = treeid;
    tree = oforest.master_node_fast(opts,filenames.video,frame_ids,locs,rseed);
    fprintf('done\n');

    
