%function to update the manual detections with new ground truth
function update_initial_detections(filename,olddetections,samplewidth,newfilename,jobid,maxjobs)

if jobid == 1
    if ~exist(newfilename,'file')
        detections.manual.frameids =[];
        detections.manual.locs = [];
        detections.manual.conf = [];
        detections.manual.clusterid = [];

        %add manual detections to annotation if not exist in annotation
        for i = 1:numel(olddetections.manual.frameids)
            id = find(olddetections.annotation.frameids == olddetections.manual.frameids(i));
            if isempty(id)
                olddetections.annotation.frameids = cat(2,olddetections.annotation.frameids,olddetections.manual.frameids(i));
                olddetections.annotation.locs = cat(3,olddetections.annotation.locs, olddetections.manual.locs(:,:,i));
            else
                for l = 1:size(olddetections.annotation.locs,2)
                    if olddetections.annotation.locs(1,l,id(1))==-999
                        olddetections.annotation.locs(:,l,id(1)) = olddetections.manual.locs(:,l,i);
                    end
                end
            end
        end

        for i = 1:numel(olddetections.annotation.frameids)
            id = find(olddetections.annotation.frameids(i)==olddetections.manual.frameids);
            if ~isempty(id)
                locs = -999*ones(2,size(olddetections.manual.locs,2));
                for l = 1:size(olddetections.manual.locs,2)
                    if olddetections.manual.locs(1,l,id(1)) == -999
                        locs(:,l) = olddetections.annotation.locs(:,l,i);
                    else
                        if olddetections.annotation.locs(1,l,i) ~= -999 && ~any(l==[4 5]) %makes sure we dont update existing elbow detections (to avoid drift)
                            locs(:,l) = olddetections.annotation.locs(:,l,i);
                        else
                            locs(:,l) = olddetections.manual.locs(:,l,id(1));
                        end
                    end
                end
                %add to new detections
                detections.manual.frameids = cat(2,detections.manual.frameids,olddetections.annotation.frameids(i));
                detections.manual.locs = cat(3,detections.manual.locs,locs);
            else
                %add to new detections
                detections.manual.frameids = cat(2,detections.manual.frameids,olddetections.annotation.frameids(i));
                detections.manual.locs = cat(3,detections.manual.locs,olddetections.annotation.locs(:,:,i));
            end
        end

        %order detections according to orignal manuals being first in the
        if ~isempty(detections.manual.frameids);
            detections.manual.conf = ones(numel(detections.manual.frameids),size(detections.manual.locs,2));
            detections.manual.clusterid = 1:numel(detections.manual.frameids);
        else
            detections = olddetections;
        end        
        
        %reorder frames 
        [~,srtid] = sort(detections.manual.frameids);
        detections.manual.frameids = detections.manual.frameids(srtid);
        detections.manual.locs = detections.manual.locs(:,:,srtid);
        save(newfilename,'detections','-v7.3');
    end
    
    for i = 1:maxjobs
       setjobcompletion(filename.joblist,i);
    end
end
