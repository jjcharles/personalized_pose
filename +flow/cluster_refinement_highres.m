%function to refine pose using dense siftflow WITHIN the cluster
function [poses, from_frame_idx, flowquality, initial_frameids] = cluster_refinement_highres(part_clusters,initial_frameids,videofilename,apply_to_locs)
%part_clusters are clustererd patches around body part detections
%initial_frameids = initial sampling from body_part_clustering after
%removal of frames with low confidence.
%apply_to_locs, specifies the joint lables where the siftflow is applied

    visualise = false;
    
    if visualise
        vidobj = VideoReader(videofilename);
    end
    
    %part_clusters.body_pose is the body part detector pose output
    poses = -999*ones(2,numel(part_clusters),numel(initial_frameids));
    from_frame_idx = ones(numel(initial_frameids),numel(part_clusters));
    flowquality = inf*ones(numel(initial_frameids),numel(part_clusters));
    patchwidth = sqrt(size(part_clusters(1).patches,1)/3);
    smallpatchwidth =  sqrt(size(part_clusters(1).cp_patches,1)/3);

    %for each part/body-part
    for p =1:numel(part_clusters)
        
        if any(p==apply_to_locs)
            fprintf('Working on label %d...',p);
            labels = unique(part_clusters(p).labels);
            nextperc = 5;

            %go through all centroids and spread the annotations
            for i = 1:numel(labels)
                %find patches corresponding to current centroid
                l = labels(i);
                labelidx = find(part_clusters(p).labels == l);

                %extract patches from structure (this consumes memory, could do with an online implementation)
                patches = part_clusters(p).patches(:,labelidx);

                %do the same for the centroid of the current cluster
                centroid = part_clusters(p).img_centroids(:,l);

                %propogate annotations between patches
                [locs, flow_energies, from_patch_idx] = flow.align_locs(patches,centroid);

                if visualise
                    savelocs = locs;
                end

                %transform locs back to input video frame size and location
                locs = ((locs - floor(patchwidth/2))-1)/(patchwidth/smallpatchwidth)+1;
                locs = part_clusters(p).body_part_locs(:,labelidx) + locs;

                %transfom patch_idx back to frameids
                temp_from_frame_idx = ones(1,numel(from_patch_idx))*part_clusters(p).centroid_frameid(l);
                
                %fill output pose array with relevant joint locations and quality measures
                for jj = 1:numel(part_clusters(p).frameids(labelidx))
                    id = find(initial_frameids==part_clusters(p).frameids(labelidx(jj)));
                    poses(:,p,id) = locs(:,jj);
                    flowquality(id,p) = flow_energies(jj);
                    from_frame_idx(id,p) = temp_from_frame_idx(jj);
                end

                if visualise %visualiation only
                    for ff = 1:size(patches,2)
                        figure(1)
                        clf
                        imagesc(uint8(reshape(patches(:,ff),[patchwidth,patchwidth,3]))); axis image
                        hold on
                        plot(savelocs(1,ff),savelocs(2,ff),'wo','markerfacecolor','w','markersize',10);
                        figure(2)
                        clf
                        img = imresize(read(vidobj,part_clusters(p).frameids(labelidx(ff))),1);
                        imagesc(img); axis image
                        hold on
                        plot(locs(1,ff),locs(2,ff),'bo','markerfacecolor','b','markersize',10);
                            plot(part_clusters(p).body_part_locs(1,labelidx(ff)),part_clusters(p).body_part_locs(2,labelidx(ff)),'wo','markerfacecolor','w','markersize',10);
                        pause
                    end
                end

                if floor(i/numel(labels)*100)>=nextperc
                    fprintf('%d%%...',floor(i/numel(labels)*100));
                    nextperc = nextperc + 5;
                end
                
            end
            fprintf('done\n');
        else
            [ia,~] = ismember(initial_frameids,part_clusters(p).frameids);
            poses(:,p,ia) = part_clusters(p).body_part_locs;
            flowquality(ia,p) = 0;
            from_frame_idx(ia,p) = part_clusters(p).frameids;
        end
    end
