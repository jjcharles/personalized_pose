%function to create a posterior weighted HOG feature
function [weighted_hog,minvalue,maxvalue] = weighted_hog(rgbimg,cpimg,cellsize)
    
    %get hog feature
    hog = features.hog(rgbimg,cellsize);
    hog = double(hog);
    
    %get forground probability
    cpd = cpimg; for i = 1:3; cpd(:,:,i) = medfilt2(cpimg(:,:,i),[30 30],'symmetric'); end;
    fp = sum(double(cpd(:,:,1:2)),3)./sum(double(cpd),3);
    
    %weight the hog according to foreground
    weighted_hog = bsxfun(@times,hog,imresize(fp.^2,[size(hog,1),size(hog,2)]));

    minvalue = min(weighted_hog(:));
    maxvalue = max(weighted_hog(:));
    
    weighted_hog = (weighted_hog-minvalue)/(maxvalue-minvalue)*255;
    weighted_hog = uint8(weighted_hog);