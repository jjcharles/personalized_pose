%function to cluster patches around body parts, based on known joint
%locations
function [part_clusters,detections] = body_part_clustering(opts,videofilename,omodel,detections,patchfilename,cache_folder)

    if ~exist('cache_folder','var')
        cache_folder = './cache/';
    end
    if ~exist(cache_folder,'dir'); mkdir(cache_folder); end

    %load in video
    vidobj = VideoReader(videofilename);

    %uniformally select frames from the video according to a set step size
    ridx = 1:vidobj.NumberOfFrames;
    R = randperm(numel(ridx));
    ridx = R(1:floor((vidobj.NumberOfFrames/opts.cluster.numneighbours)));

    %get body part locations
    filename.bodypose = sprintf('%sbodypose.mat',cache_folder);
    if ~exist(filename.bodypose,'file')
        [locs,conf] = getpartlocs(videofilename,omodel,ridx);
        detections.group.locs = locs;
        detections.group.frameids = ridx;
        detections.group.conf = conf;
        save(filename.bodypose,'detections');
    else
        load(filename.bodypose);
    end

    %get body part patches and centroid patches    
    filename.proposals = sprintf('%spartcluster.mat',cache_folder);
    if ~exist(filename.proposals,'file')
        facepatches = load(patchfilename);
        patchwidth = opts.partdetector.model.matching.patchwidth;
        part_clusters = cluster.get_part_proposals(opts,videofilename,detections,facepatches,patchwidth);
        save(filename.proposals,'part_clusters','-v7.3');
    else
        load(filename.proposals);
    end
    
    %cluster the parts
    numparts = numel(part_clusters);
    detections.group.labels = zeros(numel(detections.group.frameids),numparts);
    
    for l = 1:numparts       
        numclusters = size(part_clusters(l).centroids,2);
        
        %skip removal of patches if the joint is an elbow or wrist
        [labels,dists] = cluster.label_assignment(part_clusters(l).centroids,part_clusters(l).features); %cluster patches according to HOG descriptor
        if ~any(l==[2 3 4 5]) %only if it is not an elbow or wrist
            [h,bins] = hist(dists,15);
            [~,idh] = max(h);
            remid = dists>bins(max(1,idh-1));
            labels(remid) = -1;
             [labels, dists] = cluster.exemplarsvm_cluster(double(part_clusters(l).centroids)/255,double(part_clusters(l).features)/255,labels);
             if numel(labels>500)
                remid = dists>0.005;
             else
                 remid = [];
             end
        else
            remid = [];
        end

        fprintf('Clustering parts %d of %d into %d clusters\n',l,numparts,numclusters);
        %remove those marked as not matched
        part_clusters(l).labels = labels;
        part_clusters(l).labels(remid) = [];
        part_clusters(l).patches(:,remid) = [];
        part_clusters(l).frameids(remid) = [];
        part_clusters(l).body_part_locs(:,remid) = [];
        part_clusters(l).conf(remid) = [];
        part_clusters(l).features(:,remid) = [];
        part_clusters(l).cp_patches(:,remid) = [];
        part_clusters(l).features_minmaxval(:,remid) = [];
    end
    
    %function to return set of body part locs and confidence values on an input
    %selection of frames
    function [locs, confidence] = getpartlocs(videofilename,omodel,frameids)
        total_frames = numel(frameids);
        vidobj = VideoReader(videofilename);
        locs = zeros(2,omodel.opts.model.numclasses-1,total_frames);
        confidence = zeros(total_frames,omodel.opts.model.numclasses-1);
        fprintf('Obtaining body part locations...');
        nextperc = 25;
        for i = 1:total_frames
            fprintf('frame %d of %d\n',i,total_frames);
            framenumber = frameids(i);
            img = imresize(read(vidobj,framenumber),omodel.opts.imscale);
            [pose,~,conf] = oforest.apply_frame(omodel,img,[],[],omodel.opts.bbox,'rgb','fast');
            confidence(i,:) = conf;
            locs(:,:,i) = pose;
            if floor(i/total_frames*100)>=nextperc
                fprintf('%d%%...',round(i/total_frames*100));
                nextperc = nextperc + 25;
            end
        end
        fprintf('done\n')

