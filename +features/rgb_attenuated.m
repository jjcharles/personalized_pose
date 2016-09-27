%attenuated foreground
function feat = rgb_attenuated(opts,rgbimg,patches) 

    cpimg = features.cp(opts,rgbimg,patches);
    
    %get forground probability
    fp = sum(double(cpimg(:,:,1:2)),3)./sum(double(cpimg),3);
    
    
    %weight the rgbimg  according to foreground
    feat = uint8(bsxfun(@times,double(rgbimg),fp.^2));
    