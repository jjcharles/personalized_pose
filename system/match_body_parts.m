%function to perform clustering

function match_body_parts(opts,filename,folder_detector,cluster_folder,detections,maxjobs)

    if ~exist(sprintf('%s%04d.mat',filename.joblist,maxjobs),'file')
        %perform matching
        if ~exist(filename.unrefined_clusters,'file') && ~exist(filename.clusters,'file')
            model = oforest.load_forest_from_folder(folder_detector);
            [part_clusters,detections] = cluster.body_part_clustering(opts,filename.video,model,detections,filename.patches,cluster_folder);
            save(filename.clusters,'part_clusters','-v7.3');
            save(filename.detections,'detections');
        end
    end
  
    %set all jobs as complete
    for i = 1:maxjobs
        setjobcompletion(filename.joblist,i);
    end
        
        