function non_occluded_ids = get_non_occlusion(opts, locs, label)
%GET_NON_OCCLUSION returns id of joints (labelled according to label parameter) which are not occluded

    %get distance from labelled joint to all other joints
    locs_of_interest = locs(:,label,:);    
    distance = squeeze(sqrt(sum((bsxfun(@minus, locs, locs_of_interest)).^2)));
    
    %identify as non-occluded if all distances from joint (excluding self)
    %are less than a set radius provided in options file
    non_occluded_ids = sum(distance < opts.occlusion.radius) == 1;

    
end

