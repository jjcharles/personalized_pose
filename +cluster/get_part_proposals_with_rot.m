%function to extract patches from a video given proposed body part
%locations and augments data with rotations
function part_clusters = get_part_proposals_with_rot(opts,videofilename,detections,facepatches,patchwidth)
    
    visualise = false;   
    if visualise
        figure
    end
    
    vidobj = VideoReader(videofilename);
    numparts = size(detections.clusteredmanuals.locs,2);
    

    %setup part cluster structure
    part_clusters = struct('patches',[],'frameids',[],'labels',[],'centroids',[],'offsets',[]);
    part_clusters = cat(1,part_clusters(ones(numparts,1)));
    
    %get size of hog patch
    temphog = features.hog(rand(patchwidth,patchwidth,3),opts.partdetector.model.matching.hogcellsize);
    hogdim = size(temphog,3);
    hogpatchwidth = size(temphog,1);
    total_frames = zeros(1,numparts);
    for l = 1:numparts
        id = find(detections.group.locs(1,l,:)~=-999);
        total_frames(l) = numel(id);
        numclusters = sum(detections.clusteredmanuals.locs(1,l,:)~=-999);
        part_clusters(l).hogpatchwidth = hogpatchwidth;
        part_clusters(l).patches = repmat(uint8(0),[patchwidth*patchwidth*3,total_frames(l)]);
        part_clusters(l).frameids = detections.group.frameids(id);
        part_clusters(l).labels = ones(1,total_frames(l));
        part_clusters(l).features = repmat(uint8(0), [hogpatchwidth*hogpatchwidth*hogdim,total_frames(l)]);
        part_clusters(l).features_minmaxval = zeros(2,total_frames(l));
        part_clusters(l).cp_patches = repmat(uint8(0), [patchwidth*patchwidth*3,total_frames(l)]);
        part_clusters(l).cp_centroids = repmat(uint8(0), [patchwidth*patchwidth*3,numclusters*(numel(opts.partdetector.model.rotations)+1)]);
        part_clusters(l).centroids = repmat(uint8(0), [hogpatchwidth*hogpatchwidth*hogdim,numclusters*(numel(opts.partdetector.model.rotations)+1)]);
        part_clusters(l).centroids_minmaxval = zeros(2,numclusters*(numel(opts.partdetector.model.rotations)+1));
        part_clusters(l).img_centroids = repmat(uint8(0), [patchwidth*patchwidth*3,numclusters*(numel(opts.partdetector.model.rotations)+1)]);
        part_clusters(l).centroid_frameid = zeros(1,numclusters*(numel(opts.partdetector.model.rotations)+1));
        %add body part locs
        part_clusters(l).body_part_locs = squeeze(detections.group.locs(:,l,id));
        part_clusters(l).conf = detections.group.conf(id,l);
    end

    %extract patches for each part
    for l = 1:numparts
        remid{l} = zeros(total_frames(l),numparts); 
    end

    framecount = ones(1,numparts);
    for i = 1:numel(detections.group.frameids)
        %if part already in manual then flag for
        %removal!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!<-----------LOOK!
        
        fprintf('Extracting patches from frame %d of %d\n',i,numel(detections.group.frameids));
        framenumber = detections.group.frameids(i);
        annid = find(framenumber==detections.manual.frameids);

        highresimg = read(vidobj,framenumber);
        img = imresize(highresimg,opts.imscale);
        cp = features.cp(opts,img,facepatches.videoToColor);
        img = padarray(img,[patchwidth*4,patchwidth*4],0,'both');
        cp = padarray(cp,[patchwidth*4,patchwidth*4],0,'both');

        for l = 1:numparts
            %check if detection present
            if detections.group.locs(1,l,i)~=-999
                %check if detection already exists in manual
                if ~isempty(annid)
                    manual_for_this_label_exists = false;
                    for n = 1:numel(annid)
                        if detections.manual.locs(1,l,annid(n)) ~=-999
                            manual_for_this_label_exists = true;
                            remid{l}(framecount(l)) = 1;
                        end
                    end
                    if manual_for_this_label_exists
                        framecount(l) = framecount(l) + 1;
                        continue;
                    end
                end
                
                pos = detections.group.locs(:,l,i)+patchwidth*4;
                bbox = round([pos(1)-patchwidth/2, pos(2) - patchwidth/2,patchwidth,patchwidth]);
                datax = bbox(1):(bbox(1) + bbox(3)-1);
                datay = bbox(2):(bbox(2) + bbox(4)-1);
                tempimg = img(datay,datax,:);
                [weighted_hog,minval,maxval] = features.weighted_hog(tempimg,cp(datay,datax,:),opts.partdetector.model.matching.hogcellsize);

                tempcp = cp(datay,datax,:);

                if visualise
                    subplot(121)
                    imagesc(tempimg); axis image;
                    title(sprintf('Part %d',l));
                    subplot(122)
                    imagesc(tempcp); axis image;
                    drawnow
                    pause
                end
                part_clusters(l).features_minmaxval(:,framecount(l)) = [minval;maxval];
                part_clusters(l).patches(:,framecount(l)) = uint8(tempimg(:));
                part_clusters(l).features(:,framecount(l)) = uint8(weighted_hog(:));
                part_clusters(l).cp_patches(:,framecount(l)) = uint8(tempcp(:));
                framecount(l) = framecount(l) + 1;
            end
            
        end
        
    end
    
    %remove frames with manuals
    for l = 1:numel(part_clusters)
        remid{l} = logical(remid{l});
        part_clusters(l).frameids(remid{l}) =[];
        part_clusters(l).labels(remid{l}) = [];
        part_clusters(l).features_minmaxval(:,remid{l}) = [];
        part_clusters(l).patches(:,remid{l}) = [];
        part_clusters(l).features(:,remid{l}) = [];
        part_clusters(l).cp_patches(:,remid{l}) = [];
        part_clusters(l).body_part_locs(:,remid{l}) = [];
        part_clusters(l).conf(remid{l}) = [];
    end

    %extract centroid patches
    fprintf('Extracting centroids...')
    clustercount = ones(1,numparts);
    rotations = [0,opts.partdetector.model.rotations];
    for r = 1:numel(rotations)
        for c = 1:numel(detections.clusteredmanuals.frameids)
            framenumber = detections.clusteredmanuals.frameids(c);
            highresimg = read(vidobj,framenumber);
            img = imresize(highresimg,opts.imscale);
            [img,locs] = oforest.augmentdata(img,detections.clusteredmanuals.locs(:,:,c),rotations(r));
            img = img(:,:,:,1);
            locs = locs(:,:,1);
            
            cp = features.cp(opts,img,facepatches.videoToColor);
            cp = padarray(cp,[patchwidth*4,patchwidth*4],0,'both');

            img = padarray(img,[patchwidth*4,patchwidth*4],0,'both');

            for l = 1:numparts              
                if locs(1,l)~=-999
                    pos = locs(:,l)+patchwidth*4;
                    bbox = round([pos(1)-patchwidth/2, pos(2) - patchwidth/2,patchwidth,patchwidth]);
                    datax = bbox(1):(bbox(1) + bbox(3)-1);
                    datay = bbox(2):(bbox(2) + bbox(4)-1);
                    tempimg = img(datay,datax,:);
                    [weighted_hog, minval,maxval] = features.weighted_hog(tempimg,cp(datay,datax,:),opts.partdetector.model.matching.hogcellsize);
                    tempcp = cp(datay,datax,:);

                    part_clusters(l).centroids_minmaxval(:,clustercount(l)) = [minval;maxval];
                    part_clusters(l).centroids(:,clustercount(l)) = uint8(weighted_hog(:));
                    part_clusters(l).img_centroids(:,clustercount(l)) = uint8(tempimg(:));
                    part_clusters(l).cp_centroids(:,clustercount(l)) = uint8(tempcp(:));
                    part_clusters(l).centroid_frameid(clustercount(l)) = framenumber;
                    clustercount(l) = clustercount(l) + 1;
                end
            end
        end
    end
    
    %remove remaing clusters
    for l = 1:numparts
        if clustercount(l)<numclusters*(numel(opts.partdetector.model.rotations)+1)
            part_clusters(l).centroids_minmaxval(:,clustercount(l):end) = [];
            part_clusters(l).centroids(:,clustercount(l):end) = [];
            part_clusters(l).img_centroids(:,clustercount(l):end) =[];
            part_clusters(l).cp_centroids(:,clustercount(l):end) = [];
            part_clusters(l).centroid_frameid(clustercount(l):end) = [];
        end
        
        %remove centroids with blank frames (due to augmentations)
        remid = sum(part_clusters(l).img_centroids)==0;
        part_clusters(l).centroids_minmaxval(:,remid) = [];
        part_clusters(l).centroids(:,remid) = [];
        part_clusters(l).img_centroids(:,remid) =[];
        part_clusters(l).cp_centroids(:,remid) = [];
        part_clusters(l).centroid_frameid(remid) = [];
    end
    
    
    fprintf('done\n');
