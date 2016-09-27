%function to evaluate the joint detections and return those which we
%believe to have high confidence
%takes as input the detections struct, outputs a detections struct
%with added fields for filtered detections
function detections = best_detections(detections)

    %for each joint find best detections by thresholding the flowquality
    %score at 1400
    bestdetections = detections.refinement.flowquality < 1400; 
    bestdetections = repmat(permute(~bestdetections,[3 2 1]),[2 1 1]);
    %set other detections to -999 for invalid joints
    detections.filtered.frameids = detections.refinement.frameids;
    detections.filtered.fromframeids = detections.refinement.fromframeids;
    detections.filtered.locs = detections.refinement.locs;
    detections.filtered.locs(bestdetections) = -999;
    
    %add in manual gt frames
    detections.filtered.frameids = cat(2,detections.filtered.frameids,detections.manual.frameids);
    detections.filtered.locs = cat(3,detections.filtered.locs, detections.manual.locs);
    detections.filtered.fromframeids = cat(1, detections.filtered.fromframeids,repmat(detections.manual.frameids(:),[1 size(detections.filtered.locs,2)]));
    
    %remove all frames which have no joint detections in them
    [m,n,~] = size(detections.refinement.locs);
    remid = squeeze(sum(sum(detections.filtered.locs==-999,1),2))==m*n;
    detections.filtered.locs(:,:,remid) = [];
    detections.filtered.frameids(remid) = [];
    detections.filtered.fromframeids(remid,:) = [];
    
    %combine joints at frame
    [frameids,uid] = unique(detections.filtered.frameids);
    locs = -999*ones(2,size(detections.filtered.locs,2),numel(frameids));
    
    count = 0;
    for i = frameids
        count = count + 1;
        id = find(detections.filtered.frameids == i);
        for j = 1:numel(id)
            for l = 1:size(detections.filtered.locs,2)
                if detections.filtered.locs(1,l,id(j)) ~= -999
                    locs(:,l,count) = detections.filtered.locs(:,l,id(j));
                end
            end
        end
    end
    
    detections.filtered.locs = locs;
    detections.filtered.frameids = frameids;
    detections.filtered.fromframeids = detections.filtered.fromframeids(uid,:);
    
    