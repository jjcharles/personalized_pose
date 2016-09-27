%MULTICLASS_THRESH - find multiclass threshold value for tree
function [T, Gmax, window_index_left, window_index_right] = multiclass_thresh(opts,WI,data,feature,channel,func_type)
    window_index_left = [];
    window_index_right = [];
    Gmax = -inf;
    
    data_class = data.class(WI);
    num_samples = size(feature,2);
    T=-1;
    
     switch func_type
        case 1
            num_edges = opts.pixel_quantisation_size(channel);
            addon = 1;
            thresh_lookup = 0:(opts.pixel_quantisation_size(channel)-1);
        case 2
            num_edges = 2*opts.pixel_quantisation_size(channel)-1;
            addon = opts.pixel_quantisation_size(channel);
            thresh_lookup = -(opts.pixel_quantisation_size(channel)-1):1:(opts.pixel_quantisation_size(channel)-1);
        case 3
            num_edges = opts.pixel_quantisation_size(channel);
            addon = 1;
            thresh_lookup = 0:(opts.pixel_quantisation_size(channel)-1);
        case 4
            num_edges = 2*opts.pixel_quantisation_size(channel)-1;
            addon = 1;
            thresh_lookup = 0:(2*opts.pixel_quantisation_size(channel)-2);
        otherwise
            error('not a valid func type');
    end
    %form cumulative histogram
    HL = histtree(data_class, feature+addon, data.class_weight, num_samples, opts.numclasses, num_edges);
    HL = cumsum(HL,2);
    HR = bsxfun(@minus,HL(:,end),HL);
    normL = sum(HL);
    normR = sum(HR);
    if isfield(opts.forest,'balance_term')
        G = sum(HL.^2)./normL + sum(HR.^2)./normR + opts.forest.balance_term*(normL(end)-abs(2*normL - normL(end)));
    else
        G = sum(HL.^2)./normL + sum(HR.^2)./normR;
    end
    [Gmax, idxm] = max(G);

    if idxm~=1 || idxm==num_edges
        T = thresh_lookup(idxm);
        window_index_left = WI(feature<=T);
        window_index_right = WI(feature>T);
    end
end