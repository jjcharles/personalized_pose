%function to apply the occlusion detector on the video (accross HPC nodes)
function apply_occlusion_detection(opts,filename,folder,fieldname,tag,jobid,maxjobs)

    %load detections
    load(filename.detections);
    
    folder.occlusiondetector = check_dir(sprintf('%socclusion_detectors',folder.model),true);
    filename.occlusiondetector = sprintf('%socclusion_detector_%s.mat',folder.occlusiondetector,tag);
    
    %if detections have already have been occlusion detected then dont run
    if ~isfield(detections,'preeval')
    
        %load occlusion detector
        try
            load(filename.occlusiondetector);
        catch
            error('problem loading occlusion detector: %s\n',filename.occlusiondetector);
        end

        %setup temporary output files
        folder.temp_occlusion = check_dir(sprintf('%socclusion_%s',folder.cache,tag),true);
        filename.temp_occlusion = sprintf('%sjobid_%03d',folder.temp_occlusion,jobid);
        
        if ~exist(filename.temp_occlusion,'file')
            %split job over nodes
            split = repmat(floor(numel(detections.(fieldname).frameids)/(maxjobs)),1,maxjobs);
            split(end) = split(1) + rem(numel(detections.(fieldname).frameids),maxjobs);
            split = [1, split];
            split = cumsum(split);
            from = split(jobid);
            to = split(jobid+1)-1;
            detections.(fieldname).frameids = detections.(fieldname).frameids(from:to);
            detections.(fieldname).locs = detections.(fieldname).locs(:,:,from:to);
            
            %run occlusion detector
            detections = occlusion.filter_track(opts,filename,occlusion_model,detections,fieldname,'filtered',opts.occlusion.detection_labels);
            save(filename.temp_occlusion,'detections')
        end
        
        %compile all job output
        if jobid == 1
            waitforremainingjobs(filename,maxjobs);
            %load original detections
            load(filename.detections);
            
            %set preeval
            detections.preeval = detections.(fieldname);
            detections.(fieldname).locs = [];
            detections.(fieldname).frameids = [];
            
            for j = 1:maxjobs
                filename.temp_occlusion = sprintf('%sjobid_%03d',folder.temp_occlusion,j);
                tempdets = load(filename.temp_occlusion);
                detections.(fieldname).locs = cat(3,detections.(fieldname).locs,tempdets.detections.(fieldname).locs);
                detections.(fieldname).frameids = cat(2,detections.(fieldname).frameids,tempdets.detections.(fieldname).frameids);
            end
            
            %save the detections
            save(filename.detections,'detections');
        end
    end

    setjobcompletion(filename.joblist,jobid);
    waitforalljobs(filename,maxjobs);