%function to perform refinement on the cluster using siftflow

function apply_siftflow(filename,folder,jobid,maxjobs,itr)

%load detections
load(filename.detections);
if ~isfield(detections,'refinement')
    if ~exist(sprintf('%s%04d.mat',filename.joblist,jobid),'file')
        flow_folder = sprintf('%ssiftflow_%03d/',folder.model,itr);
        if ~exist(flow_folder,'dir'); mkdir(flow_folder); end
        filename.temp_detection = sprintf('%sdetections_temp_siftflow_%02d.mat',flow_folder,jobid);

        if ~exist(filename.temp_detection,'file')
            %load detections
            load(filename.detections);

            %load part clusters
            load(filename.clusters);

            for l = 1:numel(part_clusters)
                %split up jobs over nodes
                total_frames = numel(part_clusters(l).frameids);
                split = repmat(floor(total_frames/(maxjobs)),1,maxjobs);
                split(end) = split(1) + rem(total_frames,maxjobs);
                split = [1, split];
                split = cumsum(split);
                from = split(jobid);
                to = split(jobid+1)-1;
                remid = ones(1,total_frames);
                remid(from:to) = 0;
                remid = logical(remid);

                %remove all other bits from part_clusters
                part_clusters(l).patches(:,remid) = [];
                part_clusters(l).frameids(remid) = [];
                part_clusters(l).body_part_locs(:,remid) = [];
                part_clusters(l).conf(remid) = [];
                part_clusters(l).features(:,remid) = [];
                part_clusters(l).labels(remid) = [];
                part_clusters(l).cp_patches(:,remid) = [];
                part_clusters(l).features_minmaxval(:,remid) = [];
            end

            [poses,fromframeids,flowquality,~] = flow.cluster_refinement_highres(part_clusters,detections.group.frameids,filename.video,[1 2 3 4 5 6 7]);

            save(filename.temp_detection,'poses','fromframeids','flowquality');
        end

        if jobid == maxjobs
            waitforremainingjobs(filename,maxjobs);
            %load detections
            load(filename.detections);

            %load part_clusters
            load(filename.clusters);

            %initialise variables
            poses = -999*ones(2,numel(part_clusters),numel(detections.group.frameids));
            fromframeids = ones(numel(detections.group.frameids),numel(part_clusters));
            flowquality = inf*ones(numel(detections.group.frameids),numel(part_clusters));

            %compile all job output
            for j = 1:maxjobs

                filename.temp_detection = sprintf('%sdetections_temp_siftflow_%02d.mat',flow_folder,j);
                data = load(filename.temp_detection);

                for i = 1:size(data.poses,3)
                    for l = 1:numel(part_clusters)
                        if data.poses(1,l,i)~=-999
                            poses(:,l,i) = data.poses(:,l,i);
                            fromframeids(i,l) = data.fromframeids(i,l);
                            flowquality(i,l) = data.flowquality(i,l);
                        end
                    end
                end
            end
            detections.refinement.frameids = detections.group.frameids;
            detections.refinement.locs = poses;
            detections.refinement.fromframeids = fromframeids;
            detections.refinement.flowquality = flowquality;
            save(filename.detections,'detections');
        end
    end
end
setjobcompletion(filename.joblist,jobid);