%MASTER_NODE - builds multiclass decision tree.
function [tree,model_opts] = master_node_fast(opts, filename_video, frame_ids, locs, random_seed)
    model_opts = opts.model;
    model_opts.bbox = opts.bbox;
    model_opts.imgwidth = opts.bbox(3) + 2*model_opts.padding;
    model_opts.imgheight =opts.bbox(4) + 2*model_opts.padding;
              
    %set seed for random number generator
    s = RandStream('mt19937ar','Seed',random_seed);
    RandStream.setGlobalStream(s);
    
    save_start_stream = RandStream.getGlobalStream;
    save_start_stream = save_start_stream.State;
    
    delete_index = [];    
    %create data if no save state else load save state
    %load images into memory and get joint locations
    %calculate memory limits and subsample images accordingly
    
    [images, labels,~,total_background,newpadding] = oforest.load_images(opts,filename_video, frame_ids, locs);
    model_opts.padding = newpadding;
    model_opts.imgwidth = opts.bbox(3) + 2*newpadding;
    model_opts.imgheight =opts.bbox(4) + 2*newpadding;
    
    %sample data i.e. windows from each image
    data = oforest.sample_windows(model_opts,labels,total_background);

    %initialise tree
    tree_queue = 1;
    tree(1) = struct('left',[],'right',[],'leaf',false,'depth',1,'window_index',1:length(data.img_index));
    tree(1).distribution = ones(1,model_opts.numclasses)/model_opts.numclasses;
  
   last_depth = tree(1).depth;
   fprintf('Progress: ');
    while ~isempty(tree_queue)
        tree_index = tree_queue(1);
        if tree(tree_index).depth>last_depth
            fprintf('%d%% ',round(100*tree(tree_index).depth/model_opts.forest.maxdepth));
            last_depth = tree(tree_index).depth;
        end
        if ~tree(tree_index).leaf          
            if (tree(tree_index).depth<model_opts.forest.maxdepth)
                
                WI = tree(tree_index).window_index;
                %select a smaller sample from the windows for speed
                if numel(WI) > 200
                    if ~isfield(tree(tree_index),'dist_unnormalised')
                        [WI_small,~,class_dist] = oforest.get_smaller_sample(WI,data,zeros(1,model_opts.numclasses),200);
                    else
                        [WI_small,~,class_dist] = oforest.get_smaller_sample(WI,data,tree(tree_index).dist_unnormalised./data.class_weight,200);
                    end
                else
                    WI_small = WI;
                    N = sum(tree(tree_index).dist_unnormalised);
                    if N==0
                        class_dist = histc(data.class(WI_small),1:model_opts.numclasses);
                        N = sum(class_dist);
                    end
                    class_dist = class_dist/sum(N+eps);
                end
                    
                %for each type of test calculate the best threshold
                %value
                if  numel(WI)>model_opts.min_pernode && sum(class_dist==1)<1
                    
                    
                    max_info_gain = -inf;
                    bestT = -1;
%                     fprintf('Treeid: %d, Tree node %d. Num samples at node: %d. Tree depth: %d\n',treeid,tree_index,length(WI),tree(tree_index).depth);
                    
                    for win_samp = 1:model_opts.numsampletests
                        channel = floor(rand*model_opts.numchannels + 1);
                        for func_type = model_opts.tests_per_channel{channel}
                            for extra_samp = 1:model_opts.channel_sample_ratio(channel)
                                [feature, offset] = ...
                                    oforest.sample_node_data(model_opts,WI_small,data,images,channel,func_type,tree(tree_index).depth);
                                [T, info_gain, ~, ~] = ...
                                    oforest.multiclass_thresh(model_opts,WI_small,data,feature,channel,func_type);
                                if (T~=-1) && info_gain>max_info_gain
                                    bestchannel = channel;
                                    max_info_gain = info_gain;
                                    bestT = T;
                                    best_offset = offset;
                                    bestfunctype = uint8(func_type);
                                end
                            end
                        end
                    end
                    
                    if bestT ~= -1
                        %find index for all windows
                        feature = oforest.get_feature(model_opts,WI,data,images,bestchannel,bestfunctype,best_offset);
                        best_index_left = WI(feature<=bestT);
                        best_index_right = WI(feature>bestT);
                        CDL = hist(data.class(best_index_left),1:model_opts.numclasses);
                        CDR = hist(data.class(best_index_right),1:model_opts.numclasses);
                    end
                else
                    bestT = -1;
                end


                if (bestT ~= -1) %not a leaf node
                    tree(tree_index).test = [double(best_offset), double(bestfunctype), double(bestT), bestchannel];
                    left_index = tree_queue(end) + 1;
                    right_index = tree_queue(end) + 2;
                    tree(tree_index).left = left_index;
                    tree(tree_index).right = right_index;
                    tree(left_index).depth = tree(tree_index).depth+1;
                    tree(right_index).depth = tree(tree_index).depth+1;
                    tree(left_index).parent = tree_index;
                    tree(right_index).parent = tree_index;
                    tree(left_index).window_index = best_index_left;
                    tree(right_index).window_index = best_index_right;
                    tree(left_index).leaf = false;
                    tree(right_index).leaf = false;
                    tree(left_index).distribution = CDL.*data.class_weight/sum(CDL.*data.class_weight);
                    tree(right_index).distribution = CDR.*data.class_weight/sum(CDR.*data.class_weight);
                    tree(left_index).dist_unnormalised = CDL.*data.class_weight;
                    tree(right_index).dist_unnormalised = CDR.*data.class_weight;
                    tree_queue = [tree_queue, tree_queue(end)+1, tree_queue(end)+2];
                else
                    tree(tree_index).leaf = true;
                end        
                %remove the redundent window indicies from the parent node
                tree(tree_index).window_index = [];
            else
                tree(tree_index).leaf = true;
            end
        end
        tree_queue(1) = [];
    end
    tree(delete_index) = [];
    fprintf('100%%\n');
end