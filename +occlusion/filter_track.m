function detections = filter_track(opts, filename, occlusion_model,detections,fieldname,fromfieldname,labels)
%FILTER_TRACK filters the track by detecting occlusions along a track and
%removing track portions 
% fieldname - the field which we wish to filter e.g. temporal
% from fieldname - the field where tracks were dervied from e.g. filtered
    
    %remove joint detections in the tracked fieldname which were derived
    %from the fromfieldname
    frameids = detections.(fieldname).frameids;
    locs = detections.(fieldname).locs;
    
    for l = 1:numel(labels)
        id = detections.(fromfieldname).locs(1,labels(l),:)~=-999;
        ia = ismember(frameids,detections.(fromfieldname).frameids(id));
        locs(:,labels(l),ia) = -999;
    end
    
    %get occluded joint locations in video
    isoccluded = occlusion.apply_video(opts, occlusion_model, filename.video, frameids, locs,labels);
    
    
    %for each joint identify the occluded regions and remove
    %An occluded region is a portion of video starting with a frame
    %detected as being occluded and ending with a frame detected as being
    %not occluded
    for l = 1:numel(labels)
        tracks = occlusion.get_occluded_tracks(squeeze(detections.(fieldname).locs(:,labels(l),:)),isoccluded(:,l));
        %remove each occluded track
        for t = 1:numel(tracks)
            detections.(fieldname).locs(:,labels(l),tracks{t}) = -999;
        end
    end
        
    %clean up
    remid = sum(sum(detections.(fieldname).locs==-999))==(size(detections.(fieldname).locs,1)*size(detections.(fieldname).locs,2));
    detections.(fieldname).locs(:,:,remid) = [];
    detections.(fieldname).frameids(remid) = [];
end

