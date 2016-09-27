%output flow field based on SIFT flow and energy 
function [flow, energy] = siftflow(im1,im2,mask)
    %mask is actually 2d x, y coordinates within the image space and not a
    %binary image

    %PARAMETERS
    cellsize=3;
    gridspacing=1;
    
    flow = zeros(size(im1,1),size(im1,2),2); %sift flow turned off!!!
    
    sift1 = mexDenseSIFT((im1),cellsize,gridspacing);
    sift2 = mexDenseSIFT((im2),cellsize,gridspacing);
    energy = get_matching_term(flow,sift1,sift2,mask); 

%   %get the normalised matching term within the mask
    function mterm = get_matching_term(flow,sift1,sift2,mask)
        [M,N,~] = size(flow);
        ux = -round(flow(mask));
        uy = -round(flow(mask+M*N));
        warpmask = mask + (ux-1)*M + uy;
        warpmask(warpmask>M*N) = M*N;
        warpmask(warpmask<1) = 1;
        sift1 = double(reshape(sift1,M*N,[]));
        sift2 = double(reshape(sift2,M*N,[]));
        mterm = mean(sum(((sift1(mask,:) - sift2(warpmask,:)).^2)./(eps+(sift1(mask,:) + sift2(warpmask,:))),2));
