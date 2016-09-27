%function to propergate a single point through a set of matching frames
function [locarray, energies, from_patch_idx] = align_locs(patches,initial_patch)
%locarray is the array of joint locations relative to the patch centre
%energies is the flow energy for each patch
%from_frame_idx holds the patchidx from where the part annotaion came from
    patches = cat(2,initial_patch,[],patches);
  
    numpatches = size(patches,2);
    
    %construct array of locs
    width = sqrt(size(patches,1)/3);
    locarray = zeros(2,numpatches); %including centroid
    locarray(:,1) = ones(2,1)*floor(width/2)+1;
    energies = zeros(1,numpatches);
    from_patch_idx = zeros(1,numpatches);
    
    %construct mask
    maskwidth = 2*ceil(width/8)+1;
    mask = ones(maskwidth,maskwidth);
    
    [mr, mc] = find(mask);
    mr = mr - ceil(maskwidth/2)+ceil(width/2);
    mc = mc - ceil(maskwidth/2)+ceil(width/2);
    idxmask = (mc-1)*width + mr;

    idx = 2:numpatches;
    prop_table = cat(2,ones(numpatches-1,1),idx(:));
    
    filt = fspecial('gaussian',4,1);
    for i = 1:size(prop_table,1)
        from_idx = prop_table(i,1);
        to_idx = prop_table(i,2);

        %get SIFT flow
        im1 = uint8(reshape(patches(:,from_idx),[width width 3]));
        im1 = imfilter(im1,filt,'same','replicate');
        im2 = uint8(reshape(patches(:,to_idx),[width width 3]));
        im2 = imfilter(im2,filt,'same','replicate');
        [flow, energy] = siftflow(im2,im1,idxmask); %sift flow turned off, here we only compute the matching energy
        
        templocx = round(locarray(1,from_idx) - flow(locarray(2,from_idx),locarray(1,from_idx),1));
        templocy = round(locarray(2,from_idx) - flow(locarray(2,from_idx),locarray(1,from_idx),2));
        templocx(templocx>width) = width;
        templocx(templocx<1) = 1;
        templocy(templocy>width) = width;
        templocy(templocy<1)= 1;
        
        locarray(1,to_idx) = templocx;
        locarray(2,to_idx) = templocy;
        energies(to_idx) = energy;
        from_patch_idx(to_idx) = from_idx;
    end
    
    locarray(:,1) = []; %remove centroid joint location
    energies(1) = [];
    from_patch_idx(1) = [];    