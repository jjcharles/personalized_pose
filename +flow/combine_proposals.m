%function to combine proposals and formulate the statistics per frame
%works using detection struct as input
%provides a contribution field with all stats
function detections = combine_proposals(detections,videofilename)

    visualise = true;
    
    if visualise && exist('videofilename','var')
        vidobj = VideoReader(videofilename);
    end

    %initialise
    detections.temporal.locs = [];
    detections.temporal.frameids = [];
    detections.temporal.spread = [];
    detections.temporal.flowq = [];
    detections.temporal.siftflowq = [];
    detections.temporal.conf = [];
    detections.temporal.num_contribs = [];
    
    %remove rubbish frames
    remid = sum(sum(detections.temporal.alllocs==-999))==(size(detections.temporal.alllocs,1)*size(detections.temporal.alllocs,2));
    detections.temporal.alllocs(:,:,remid) =[];
    detections.temporal.allframeids(remid) = [];
    detections.temporal.allflowq(remid,:) = [];
    detections.temporal.fromframeids(remid) = [];
    
    numjoints = size(detections.temporal.alllocs,2);
    
    count = 0;
    numuniqueframes = numel(unique(detections.temporal.allframeids));
    for i = unique(detections.temporal.allframeids)
        
        id = find(detections.temporal.allframeids==i);
        detections.temporal.frameids = cat(2,detections.temporal.frameids,i);
        count = count + 1;
        fprintf('evaluating frame %d of %d\n',count,numuniqueframes);
        if ~isempty(id)
            numframes = numel(id);
            %initialise
            detections.temporal.contributing(count).frameid = zeros(1,numframes);
            detections.temporal.contributing(count).flowq = zeros(numframes,numjoints);
            detections.temporal.contributing(count).siftflowq = zeros(numframes,numjoints);
            detections.temporal.contributing(count).conf = zeros(numframes,numjoints);
            detections.temporal.contributing(count).loc = zeros(2,numjoints,numframes);
            for f = 1:numframes
                %loop through each joint and see which one is valid
                detections.temporal.contributing(count).frameid(f) = detections.temporal.fromframeids(id(f));
                tempflowq = inf(1,numjoints);
                tempsiftflowq = inf(1,numjoints);
                tempconf = zeros(1,numjoints);
                templocs = -999*ones(2,numjoints);
                
                for j = 1:numjoints
                    if detections.temporal.alllocs(1,j,id(f))~=-999
                        siftid = detections.refinement.frameids==detections.temporal.contributing(count).frameid(f);
                        
                        if sum(siftid)==0
                            tempsiftflowq(j) = 0;
                            confid = detections.group.frameids == detections.temporal.contributing(count).frameid(f);
                            
                            if sum(confid)==0 %check if it comes from an initial annotation
                                if  any(detections.manual.frameids==detections.temporal.contributing(count).frameid(f))
                                    tempconf(j) = 1;
                                else
                                    warning('failed to track confidence score\n');
                                end
                            else
                                tempconf(j) = detections.group.conf(confid,j);
                            end
                        else
                            tempsiftflowq(j) = detections.refinement.flowquality(siftid,j);
                            confid = detections.group.frameids == detections.refinement.frameids(siftid);
                            tempconf(j) = detections.group.conf(confid,j);
                        end
                        
                        tempflowq(j) = detections.temporal.allflowq(id(f),j);
                        templocs(:,j) = detections.temporal.alllocs(:,j,id(f));
                    end
                end
                detections.temporal.contributing(count).flowq(f,:) = tempflowq;
                detections.temporal.contributing(count).siftflowq(f,:) = tempsiftflowq;
                detections.temporal.contributing(count).conf(f,:) = tempconf;
                detections.temporal.contributing(count).loc(:,:,f) = templocs;
            end
        end
    end    
    firstdraw = true;
    
    %for all frames with joints calculate the stats
    for i = 1:numel(detections.temporal.frameids)        
        locs = detections.temporal.contributing(i).loc;
        contribs = detections.temporal.contributing(i).frameid;
        
        invalidlocs = repmat(locs(1,:,:)==-999,[2 1 1]);
        
        flowq = detections.temporal.contributing(i).flowq;
        conf = detections.temporal.contributing(i).conf;

        siftflowq = detections.temporal.contributing(i).siftflowq;
        
        %for each joint make a decision on its location
        frame_locs = -999*ones(2,numjoints);
        frame_spread = zeros(1,numjoints);
        frame_flowq = zeros(1,numjoints);
        frame_siftflowq = zeros(1,numjoints);
        frame_conf= zeros(1,numjoints);
        frame_num_contribs = zeros(1,numjoints);
        
        for j = 1:numjoints
            particle = [];
            %sample joint location based on weights
            x = squeeze(locs(1,j,:));
            x(squeeze(invalidlocs(1,j,:))) = [];

            
            if ~isempty(x)
                y = squeeze(locs(2,j,:));
                y(squeeze(invalidlocs(2,j,:))) = [];
                j_conf = conf(squeeze(~invalidlocs(1,j,:)),j);
                j_siftflowq = siftflowq(squeeze(~invalidlocs(1,j,:)),j);
                j_flowq = flowq(squeeze(~invalidlocs(1,j,:)),j);
                j_num_contribs = numel(unique(contribs(squeeze(~invalidlocs(1,j,:)))));

                %check the spread
                spreadval = sqrt(var(y)+var(x));
                %do checks
%                 if j~=1 %always use the head but check the other joints
                removeid = j_siftflowq > 2000 | j_flowq > 2500 | j_num_contribs < 3;
                if sum(removeid)==numel(x); continue; end;
                if spreadval > inf; continue; end

                y(removeid) = [];
                x(removeid) = [];
                j_conf(removeid) =[];
                j_siftflowq(removeid) =[];
                j_flowq(removeid) = [];
                
                weight = j_conf;
                %set all weights equal
                weight(:) = 1/numel(weight);

                %resample location
                for p = 1:numel(x)
                    particle(p).x = x(p);
                    particle(p).y = y(p);
                    particle(p).weight = weight(p);
                    if isempty(particle(p).x); keyboard; end
                end
                
                if visualise
                    for p = 1:numel(particle)
                        particlefordraw(i).weight = 1/numel(particle);
                    end
                    particlefordraw = pfilter.resample(particle,500);
                end
                
                %get prediction and compute stats on evaluation measures
                P = pfilter.get_prediction(particle);
                frame_locs(:,j) = P;
                frame_spread(j) = spreadval;
                frame_flowq(j) = mean(j_flowq);
                frame_siftflowq(j) = mean(j_siftflowq);
                frame_conf(j) = mean(j_conf);
                frame_num_contribs(j) = j_num_contribs;
            
                if visualise && exist('videofilename','var') && j == 3
                    img = read(vidobj,detections.temporal.frameids(i));
                    if firstdraw
                        hndl = pfilter.draw(particlefordraw,img);
                        h_title = title(sprintf('joint label %d conf %f, sift %f, flow %f, spread %f',j,mean(j_conf),mean(j_siftflowq),mean(j_flowq),spreadval));
                        firstdraw = false;
                    else
                        pfilter.draw(particlefordraw,img,hndl);
                        set(h_title,'string',sprintf('joint label %d conf %f, sift %f, flow %f, spread %f',j,mean(j_conf),mean(j_siftflowq),mean(j_flowq),spreadval));
                    end
                    drawnow
                end
            end
        end
        detections.temporal.locs = cat(3,detections.temporal.locs,frame_locs);
        detections.temporal.spread = cat(1,detections.temporal.spread,frame_spread);
        detections.temporal.flowq = cat(1,detections.temporal.flowq,frame_flowq);
        detections.temporal.siftflowq = cat(1,detections.temporal.siftflowq,frame_siftflowq);
        detections.temporal.conf = cat(1,detections.temporal.conf,frame_conf);
        detections.temporal.num_contribs = cat(1,detections.temporal.num_contribs,frame_num_contribs);
    end
    
    %remove all frames which have no joint detections in them
    [m,n,~] = size(detections.temporal.locs);
    remid = squeeze(sum(sum(detections.temporal.locs==-999,1),2))==m*n;
    detections.temporal.locs(:,:,remid) = [];
    detections.temporal.spread(remid,:) = [];
    detections.temporal.flowq(remid,:) = [];
    detections.temporal.siftflowq(remid,:) = [];
    detections.temporal.conf(remid,:) = [];
    detections.temporal.frameids(remid) = [];
    detections.temporal.contributing(remid) = [];
    detections.temporal.num_contribs(remid,:) = [];
    

   