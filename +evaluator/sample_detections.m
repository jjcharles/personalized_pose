%resample detections so that there is a maximal coverage of locations
%across each object/body_part type
%normalises to head position
function detections = sample_detections(detections,field_name,patch_width,num_samples_per_part)

    num_parts = size(detections.(field_name).locs,2);
    
    locs = [];
    frameids = [];
    
    %normalise to head position
    inputlocs = detections.(field_name).locs;
    remid = inputlocs ==-999;
    offset = bsxfun(@minus,inputlocs,inputlocs(:,1,:));
    inputlocs = inputlocs + offset;
    inputlocs(remid) = -999;
    
    for p = 1:num_parts
        id = find(detections.(field_name).locs(1,p,:)~=-999); 
        if ~isempty(id)
            sampleid = sample_uniformally(squeeze(inputlocs(:,p,id)),patch_width,num_samples_per_part);
            templocs = -999*ones(2,num_parts,numel(sampleid));
            templocs(:,p,:) = inputlocs(:,p,id(sampleid)) - offset(:,p,id(sampleid));
            locs = cat(3, locs, templocs);
            frameids = cat(2,frameids,detections.(field_name).frameids(id(sampleid)));
        end
    end
    
    %combine frameids and joints
    tempframeids = unique(frameids);
    detections.sampled.frameids = tempframeids;
    detections.sampled.locs =-999*ones(2,num_parts,numel(tempframeids));
    for f = 1:numel(tempframeids)
        id = find(frameids==tempframeids(f));
        for n = 1:numel(id)
            valid = locs(1,:,id(n))~=-999;
            detections.sampled.locs(:,valid,f) = locs(:,valid,id(n));
        end
    end