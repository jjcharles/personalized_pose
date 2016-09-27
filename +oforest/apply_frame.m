%function to apply the general forest to a frame
function [locs, dist, conf, leafids] = apply_frame(omodel,img,seg, patches, bbox, featuretype, testing_speed,filter_width)
%bbox is the bounding box where the forest is applied

    if ~exist('filter_width','var')
        filter_width = 4;
    end
    
    switch lower(featuretype)
        case 'hardsegcp'
            feat = features.hardsegcp(gmodel.rmodel.opts, img, patches, seg, bbox);  
        case 'rgb'
            feat = imfilter(img,fspecial('gaussian',ceil(5*omodel.opts.model.modelscale),3*omodel.opts.model.modelscale),'replicate');
        case 'quant_segcp'
            feat = features.quant_segcp(omodel.opts,img,patches,seg);
    end
    
    if ~exist('testing_speed','var')
        [locs, dist, conf, leafids] = oforest.apply_forest(omodel,feat,bbox);
    else
        switch lower(testing_speed)
            case 'fast'
                [locs, dist, conf, leafids] = oforest.apply_forest_fast(omodel,feat,bbox);
            case 'slow'
                [locs, dist, conf, leafids] = oforest.apply_forest(omodel,feat,bbox,true,filter_width);
            case 'evaluator'
                locs = oforest.apply_forest(omodel,feat,bbox,true,filter_width);
                dist = []; conf = []; leafids = [];
        end
    end
    
