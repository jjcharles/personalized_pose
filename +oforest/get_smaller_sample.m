%function to sample a uniform selection of windows across all classes
function [WI_small,winid,norm_class_dist] = get_smaller_sample(WI,data,class_dist,maxsample)

    num_diff_classes = numel(class_dist);
    N = sum(class_dist);
    if N==0
        class_dist = histc(data.class(WI),1:num_diff_classes);
        N = sum(class_dist);
    end
    norm_class_dist = class_dist/sum(N+eps);

    
    %sample from distribution
    class_sample = zeros(1,maxsample);
    cum_class = cumsum(norm_class_dist);
    for i = 1:maxsample
        class_sample(i) = sum(rand>cum_class)+1;
    end
    class_number = histc(class_sample,1:num_diff_classes);
    class_number = round(min(cat(1,class_number,class_dist)));
    
    WI_small = zeros(1,sum(class_number));
    winid = zeros(1,sum(class_number));
    count = 1;
    for c = 1:num_diff_classes
        if class_number(c)==0
            continue;
        else
            classidx = find(data.class(WI)==c);
            R = randperm(numel(classidx));
            WI_small(count:(count + class_number(c)-1)) = WI(classidx(R(1:class_number(c))));
            winid(count:(count + class_number(c)-1)) = classidx(R(1:class_number(c)));
            count = count + class_number(c);
        end
    end
    