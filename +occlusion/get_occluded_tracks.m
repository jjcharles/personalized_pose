function tracks = get_occluded_tracks(locs,isoccluded)
%GET_OCCLUDED_REGIONS returns occluded tracks
%idx is a cell array of occluded regions
%locs is a 2 by N array of joint locations for ONE joint
%isoccluded is a 1 by N binary array indicating locations of occlusion
    
    minzeros = 0;
    %assess track occlusion for each track in the input
    numlocs = size(locs,2);
    tracks = {};
    temptrack = [];
    count = 1;
    numzeros = 0;
    ontrack = false;
    for idx = 1:numlocs
        if locs(1,idx)~=-999
            if isoccluded(idx)
                ontrack = true;
                numzeros = 0;
            else
                if ontrack
                    numzeros = numzeros + 1;
                    if numzeros > minzeros
                        ontrack = false;
                        tracks{count} = temptrack;
                        temptrack = [];
                        count = count + 1;
                    end
                end
            end
            if ontrack
                temptrack = cat(2,temptrack,idx);
            end
        else
            if ~isempty(temptrack)
                ontrack = false;
                tracks{count} = temptrack;
                temptrack = [];
                count = count + 1;
            end
            continue
        end
        
    end
    
    if ontrack
        tracks{count} = temptrack;
    end
end




