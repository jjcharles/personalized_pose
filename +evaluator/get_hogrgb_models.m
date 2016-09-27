%function which trains an svm evaluator for both hog and rgb features
%it returns two different models one for hog and one for rgb
%uses a hold out set of validation data to tune the svm thresholds
function [hogmodel, rgbmodel] = get_hogrgb_models(opts,filename,folder,detections,fieldname,modelscale)
    %subsample detection to use a maximum of opts.evaluator.maxtrainframes
    numdets = numel(detections.(fieldname).frameids);
    sampleid = round(linspace(1,numdets,min([opts.evaluator.maxtrainframes,numdets])));
    
    detections.(fieldname).locs = detections.(fieldname).locs(:,:,sampleid);
    detections.(fieldname).frameids = detections.(fieldname).frameids(sampleid);
    %get rgb model
    [left_shape,right_shape] = evaluator.train_rgb_model(opts,filename,folder,detections,fieldname,modelscale);
    rgbmodel.left_shape = left_shape;
    rgbmodel.right_shape = right_shape;
    rgbmodel.opts = opts;
    
    %get hog model
    [left_shape,right_shape] = evaluator.train_hog_model(opts,filename,folder,detections,fieldname,modelscale);
    hogmodel.left_shape = left_shape;
    hogmodel.right_shape = right_shape;
    hogmodel.opts = opts;
    
    