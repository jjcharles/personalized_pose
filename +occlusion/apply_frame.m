function [label,response] = apply_frame(occlusion_model,loc,input_frame )
%APPLY_FRAME apply occlusion model to input frame at a specific location
% occlusion_model - model which comes from running occlusion.train_models

    %get patch
    rgbpatch = getpatch(loc,occlusion_model.opts.patchwidth,input_frame);
    hogpatch = single(features.hog(rgbpatch,occlusion_model.opts.hog_cell_size));
    rgbpatch = rgbpatch(1:occlusion_model.opts.rgbsubsamp:end,1:occlusion_model.opts.rgbsubsamp:end,:);
    
    %classify
    [~,~,decision_rgb] = predict_linsvm(0,sparse(double(rgbpatch(:)')), occlusion_model.rgbmodel,'-q');
    label_rgb = decision_rgb > occlusion_model.rgbmodel.thresh;
    [~,~,decision_hog] = predict_linsvm(0,sparse(double(hogpatch(:)')), occlusion_model.hogmodel,'-q');
    label_hog = decision_hog > occlusion_model.hogmodel.thresh;
    
    %label_hog/label_rgb of 1 means there is NOT an occlusion
    %however we set label to 1 if there IS an occlusion
    label = ~(label_rgb && label_hog); %either rgb or hog have to be convinced of occlusion for detection to fire.
    response = decision_rgb + decision_hog;
end

