%function to extract patches from a video given proposed body part
%locations
function part_clusters = get_part_proposals(opts,videofilename,detections,facepatches,patchwidth)
    
    visualise = false;   
    if visualise
        figure
    end
    
    vidobj = VideoReader(videofilename);
    numparts = size(detections.manual.locs,2);
    numclusters = size(detections.manual.locs,3);
    total_frames = numel(detections.group.frameids);
    
    %setup part cluster structure
    part_clusters = struct('patches',[],'frameids',[],'labels',[],'centroids',[],'offsets',[]);
    part_clusters = cat(1,part_clusters(ones(numparts,1)));
    for l = 1:numparts
        part_clusters(l).patches = repmat(uint8(0),[patchwidth*patchwidth*3,total_frames]);
        part_clusters(l).frameids = detections.group.frameids;
        part_clusters(l).labels = ones(1,total_frames);
        part_clusters(l).features = repmat(uint8(0), [ceil(patchwidth/2)*ceil(patchwidth/2)*36,total_frames]);
        part_clusters(l).features_minmaxval = zeros(2,total_frames);
        part_clusters(l).cp_patches = repmat(uint8(0), [patchwidth*patchwidth*3,total_frames]);
        part_clusters(l).cp_centroids = repmat(uint8(0), [patchwidth*patchwidth*3,numclusters]);
        part_clusters(l).centroids = repmat(uint8(0), [ceil(patchwidth/2)*ceil(patchwidth/2)*36,numclusters]);
        part_clusters(l).centroids_minmaxval = zeros(2,numclusters);
        part_clusters(l).img_centroids = repmat(uint8(0), [patchwidth*patchwidth*3,numclusters]);
        part_clusters(l).centroid_frameid = zeros(1,numclusters);
    end

    %extract patches for each part
    count = 1;
    for i = 1:total_frames
        fprintf('Extracting patches from frame %d of %d\n',i,total_frames);
        framenumber = detections.group.frameids(i);
        highresimg = read(vidobj,framenumber);
        img = imresize(highresimg,opts.imscale);
        cp = features.cp(opts,img,facepatches.videoToColor);
        img = padarray(img,[patchwidth*4,patchwidth*4],0,'both');
        cp = padarray(cp,[patchwidth*4,patchwidth*4],0,'both');

        for l = 1:numparts
            pos = detections.group.locs(:,l,i)+patchwidth*4;
            bbox = round([pos(1)-patchwidth/2, pos(2) - patchwidth/2,patchwidth,patchwidth]);
            datax = bbox(1):(bbox(1) + bbox(3)-1);
            datay = bbox(2):(bbox(2) + bbox(4)-1);
            tempimg = img(datay,datax,:);
            [weighted_hog,minval,maxval] = features.weighted_hog(tempimg,cp(datay,datax,:));
            
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
            part_clusters(l).features_minmaxval(:,count) = [minval;maxval];
            part_clusters(l).patches(:,count) = uint8(tempimg(:));
            part_clusters(l).features(:,count) = uint8(weighted_hog(:));
            part_clusters(l).cp_patches(:,count) = uint8(tempcp(:));
        end
        count = count + 1;
    end

    %extract centroid patches
    fprintf('Extracting centroids...')
    clustercount = ones(1,numparts);
    for c = 1:numclusters
        framenumber = detections.manual.frameids(c);
        highresimg = read(vidobj,framenumber);
        img = imresize(highresimg,opts.imscale);
        cp = features.cp(opts,img,facepatches.videoToColor);
        cp = padarray(cp,[patchwidth*4,patchwidth*4],0,'both');

        img = padarray(img,[patchwidth*4,patchwidth*4],0,'both');
        for l = 1:numparts
            
            if detections.manual.locs(1,l,c)~=-999
                pos = detections.manual.locs(:,l,c)+patchwidth*4;
                bbox = round([pos(1)-patchwidth/2, pos(2) - patchwidth/2,patchwidth,patchwidth]);
                datax = bbox(1):(bbox(1) + bbox(3)-1);
                datay = bbox(2):(bbox(2) + bbox(4)-1);
                tempimg = img(datay,datax,:);
                [weighted_hog, minval,maxval] = features.weighted_hog(tempimg,cp(datay,datax,:));
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
    
    %remove remaing clusters
    for l = 1:numparts
        if clustercount(l)<numclusters
            part_clusters(l).centroids(:,clustercount(l):end) = [];
            part_clusters(l).img_centroids(:,clustercount(l):end) =[];
            part_clusters(l).cp_centroids(:,clustercount(l):end) = [];
            part_clusters(l).centroid_frameid(clustercount(l):end) = [];
        end
    end
    
    fprintf('done\n');
