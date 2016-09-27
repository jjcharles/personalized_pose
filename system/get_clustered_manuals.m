%function to form clustered manuals
function detections = get_clustered_manuals(opts,filename,detections,feature_type,jobid,maxjobs)

if jobid == 1
    joblistfilename = sprintf('%s%04d.mat',filename.joblist,jobid);
    if ~exist(joblistfilename,'file')
        fprintf('Getting clustered manuals...\n');
        numclusters = 200;
        maxframes = 5000;
        vidobj = VideoReader(filename.video);
        
        if strcmp(feature_type,'rgb_attenuated');
            %load colour histogram for cp image
            load(filename.patches);
        end

        %for each part extract a scaled patch and cluster into 200 parts
        frameids = detections.manual.frameids;
        locs = detections.manual.locs;
        numparts = size(locs,2);
        numframes = numel(frameids);

        if numframes > maxframes %subsample
            sampleid = round(linspace(1,numel(frameids),maxframes));
            frameids = frameids(sampleid);
            locs = locs(:,:,sampleid);
            numframes = maxframes;
        end
        
        patchwidth = 25;
        %initialise
        for l = 1:numparts
            id = find(locs(1,l,:)~=-999);
            parts(l).patches = repmat(uint8(0),[patchwidth*patchwidth*3,numel(id)]);
            parts(l).frameids = frameids(id);
            parts(l).locs = locs(:,l,id);
        end
        count = ones(1,numparts);
        for f = 1:numframes
            fprintf('Getting clustered manuals frame %d of %d\n',f,numframes);
            for l = 1:numparts
                if locs(1,l,f)~=-999 %extract part
                    switch feature_type
                        case 'rgb_attenuated'
                            img = features.rgb_attenuated(opts,imresize(read(vidobj,frameids(f)),opts.imscale),videoToColor);
                        case 'rgb'
                            img = imresize(read(vidobj,frameids(f)),opts.imscale);
                    end
                    
                    patch  = getpatch(locs(:,l,f),opts.partdetector.model.matching.patchwidth,img);
                    patch = imresize(patch,[patchwidth,patchwidth]);
                    parts(l).patches(:,count(l)) = patch(:);
                    count(l) = count(l) + 1;
                end
            end
        end

        %cluster the parts and set centroids as the new detections.clusteredmanuals
        detections.clusteredmanuals.frameids = 1:max(frameids);
        detections.clusteredmanuals.locs = -999*ones(2,numparts,max(frameids));
        fprintf('Clustering the manuals...');
        for l = 1:numparts
            [centroids, ~] = vl_kmeans(single(parts(l).patches),min(size(parts(l).patches,2),numclusters),'initialization','PLUSPLUS','algorithm','elkan');
            centroids = uint8(centroids);
            index = flann_build_index(parts(l).patches,struct('algorithm','kdtree','tree',16));
            search_struct = struct('checks',128);
            [centroid_id,~] = flann_search(index,centroids,1,search_struct);
            detections.clusteredmanuals.locs(:,l,parts(l).frameids(centroid_id)) = parts(l).locs(:,:,centroid_id);        
        end

        %remove frames with no locs
        idrem = sum(sum(detections.clusteredmanuals.locs==-999))==(2*numparts);
        detections.clusteredmanuals.locs(:,:,idrem) = [];
        detections.clusteredmanuals.frameids(idrem) =[];
        save(filename.detections,'detections');
        fprintf('done\n');
    end
end

setjobcompletion(filename.joblist,jobid);
waitforalljobs(filename,maxjobs);
load(filename.detections);
