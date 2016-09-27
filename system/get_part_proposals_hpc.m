%function to get part proposals on the cluster
function part_clusters = get_part_proposals_hpc(opts,filename,detections,jobid,maxjobs,cache_folder)

    mainfilename = sprintf('%spartcluster.mat',cache_folder);
    if ~exist(mainfilename,'file')
        %split up jobs
        split = repmat(floor(numel(detections.group.frameids)/(maxjobs)),1,maxjobs);
        split(end) = split(1) + rem(numel(detections.group.frameids),maxjobs);
        split = [1, split];
        split = cumsum(split);
        from = split(jobid);
        to = split(jobid+1)-1;

        detections.group.frameids = detections.group.frameids(from:to);
        detections.group.conf = detections.group.conf(from:to,:);
        detections.group.locs = detections.group.locs(:,:,from:to);

        %load face patches
        patchwidth = opts.partdetector.model.matching.patchwidth;
        facepatches = load(filename.patches);

        tempfilename = sprintf('%spart_clusters_temp_%03d.mat',cache_folder,jobid);
        if ~exist(tempfilename,'file')
            part_clusters = cluster.get_part_proposals_with_rot(opts,filename.video,detections,facepatches,patchwidth);
            save(tempfilename,'part_clusters','-v7.3');
        end

        %compile all once complete
        if jobid==maxjobs
            waitforremainingjobs(filename,maxjobs)
            for i = 1:maxjobs
                tempfilename = sprintf('%spart_clusters_temp_%03d.mat',cache_folder,i);
                tempdata = load(tempfilename);
                if i == 1
                    part_clusters = tempdata.part_clusters;
                else
                    for l = 1:numel(part_clusters)
                        if ~isempty(tempdata.part_clusters(l).conf)
                            part_clusters(l).features_minmaxval = cat(2,part_clusters(l).features_minmaxval,tempdata.part_clusters(l).features_minmaxval); 
                            part_clusters(l).patches = cat(2,part_clusters(l).patches,tempdata.part_clusters(l).patches);
                            part_clusters(l).cp_patches = cat(2,part_clusters(l).cp_patches,tempdata.part_clusters(l).cp_patches);
                            part_clusters(l).frameids = cat(2,part_clusters(l).frameids,tempdata.part_clusters(l).frameids);
                            part_clusters(l).labels = cat(2,part_clusters(l).labels,tempdata.part_clusters(l).labels);
                            part_clusters(l).features = cat(2,part_clusters(l).features,tempdata.part_clusters(l).features);
                            part_clusters(l).body_part_locs = cat(2,part_clusters(l).body_part_locs,tempdata.part_clusters(l).body_part_locs);
                            if isempty(part_clusters(l).conf)
                                part_clusters(l).conf = tempdata.part_clusters(l).conf;
                            else
                                part_clusters(l).conf = cat(1,part_clusters(l).conf,tempdata.part_clusters(l).conf);
                            end
                        end
                    end
                end
            end

            %save the body part locations
            save(mainfilename,'part_clusters','-v7.3');
        end
    end
    
    %set completion tag in jobfile
    setjobcompletion(filename.joblist,jobid);

    
    
    
    
    