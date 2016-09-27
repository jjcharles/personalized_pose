function detections = temporal_propergation(opts,filename,folder,jobid,maxjobs,itr)

load(filename.detections);
    
if ~exist(sprintf('%s%04d.mat',filename.joblist,jobid),'file') && ~isfield(detections,'annotation')
    %use temporal flow
    detections = evaluator.best_detections(detections);

    %split up jobs
    split = repmat(floor(numel(detections.filtered.frameids)/(maxjobs)),1,maxjobs);
    split(end) = split(1) + rem(numel(detections.filtered.frameids),maxjobs);
    split = [1, split];
    split = cumsum(split);
    from = split(jobid);
    to = split(jobid+1)-1;

    frameids = detections.filtered.frameids(from:opts.flow.numneighbours:to);
    locs = detections.filtered.locs(:,:,from:opts.flow.numneighbours:to);

    %setup tempfile name for the temporal refinement
    flow_folder = sprintf('%stemporal_flow_%03d/',folder.model,itr);
    if ~exist(flow_folder,'dir'); mkdir(flow_folder); end
    filename.temporal = sprintf('%sdetections_temp_%02d.mat',flow_folder,jobid);
    if ~exist(filename.temporal,'file')
        [refinedlocs, refinedframes,alllocs,allframeids,fromframeids,allflowq] = flow.temporal_refinement(opts,filename,locs,frameids);
        detections.temporal.allframeids = allframeids;
        detections.temporal.alllocs = alllocs;
        detections.temporal.fromframeids = fromframeids;
        detections.temporal.allflowq = allflowq;
        detections = flow.combine_proposals(detections);
        save(filename.temporal,'detections');
    else
        load(filename.temporal);
    end


    %if last job then wait for all other jobs to finish and compile the joint
    %detections
    if jobid == maxjobs
        waitforremainingjobs(filename,maxjobs);
        %compile the detections
        locs = [];
        frameids = [];
        fromframeids = [];
        siftflowq = [];
        flowq = [];
        spread = [];
        numcontribs = [];

        
        for i = 1:maxjobs
            fprintf('Combining output from job %d of %d\n',i,maxjobs);
            load( sprintf('%sdetections_temp_%02d.mat',flow_folder,i));
            
            if i == 1
                locs = cat(3, locs, detections.temporal.locs);
                frameids = cat(2, frameids, detections.temporal.frameids);
                flowq = cat(1,flowq,detections.temporal.flowq);
                siftflowq = cat(1,siftflowq,detections.temporal.siftflowq);
                spread = cat(1,spread,detections.temporal.spread);
                numcontribs = cat(1,numcontribs,detections.temporal.num_contribs);
            else %consider the overlap between current frames and next job
                [overlapping_frameids,ib] = ismember(frameids,detections.temporal.frameids);
                id = find(overlapping_frameids);
                if isempty(id)
                    locs = cat(3, locs, detections.temporal.locs);
                    frameids = cat(2, frameids, detections.temporal.frameids);
                    flowq = cat(1,flowq,detections.temporal.flowq);
                    siftflowq = cat(1,siftflowq,detections.temporal.siftflowq);
                    spread = cat(1,spread,detections.temporal.spread);
                    numcontribs = cat(1,numcontribs,detections.temporal.num_contribs);
                else
                    %replace existing locs with best proposal, i.e. the one
                    %with more contributions
                    for f = 1:numel(id)
                        for l = 1:size(detections.temporal.locs,2)
                            if locs(1,l,id(f)) ~= -999 %replace only if num contribs is more
                                if numcontribs(id(f),l) < detections.temporal.num_contribs(ib(id(f)),l)
                                    locs(:,l,id(f)) = detections.temporal.locs(:,l,ib(id(f)));
                                    numcontribs(id(f),l) = detections.temporal.num_contribs(ib(id(f)),l);
                                end
                            else
                                locs(:,l,id(f)) = detections.temporal.locs(:,l,ib(id(f)));
                            end
                        end
                    end
                    lastframeid = find(overlapping_frameids,1,'last');
                    remaining_portion = (ib(lastframeid) + 1):numel(detections.temporal.frameids);
                    %concatenate remaining info
                    locs = cat(3, locs, detections.temporal.locs(:,:,remaining_portion));
                    frameids = cat(2, frameids, detections.temporal.frameids(remaining_portion));
                    flowq = cat(1,flowq,detections.temporal.flowq(remaining_portion,:));
                    siftflowq = cat(1,siftflowq,detections.temporal.siftflowq(remaining_portion,:));
                    spread = cat(1,spread,detections.temporal.spread(remaining_portion,:));
                    numcontribs = cat(1,numcontribs,detections.temporal.num_contribs(remaining_portion,:));
                end
            end
        end

        detections.temporal.locs = locs;
        detections.temporal.frameids = frameids;
        detections.temporal.spread = spread;
        detections.temporal.flowq = flowq;
        detections.temporal.num_contribs = numcontribs;
        detections.temporal.siftflowq = siftflowq;
        
        %set annotation to temporal data ready for evaluation
        detections.annotation = detections.temporal;
        save(filename.detections,'detections','-v7.3');
    end
else
    load(filename.detections);
end

%set completion tag in jobfile
setjobcompletion(filename.joblist,jobid);
