%SAMPLE_WINDOWS - samples with windows from the loaded images
function points = sample_windows(opts,labels,total_background)

    %initialise the points array
    numbackgroundextras = 100;
    patch = oforest.make_patch(opts.patchwidth);
    total_points = 0;
    for i = 1:size(labels,3)
        numspots = 0;
        for class = 1:(opts.numclasses-1)
            if any(labels(:,class,i)<0); continue; end %skip if label missing
            total_points = total_points + size(patch,1);
            numspots = numspots + 1;
        end
        total_points = total_points + opts.numwindows-numspots*size(patch,1);
    end
    total_points = total_points + numbackgroundextras*total_background;
    
    points = struct('x',uint16(zeros(1,total_points)),'y',uint16(zeros(1,total_points)),...
        'class',uint8(zeros(1,total_points)),'img_index',uint32(zeros(1,total_points)),...
        'class_weight',zeros(1,opts.numclasses));
    
    
    
    
    %sample points from both negative and positive classes, with
    %replacement
    count = 1;
    for i = 1:size(labels,3)
        p=1;
        store_joint = [];
        %for each image use all points from the joint patch, then
        %sample from the background
        for class = 1:(opts.numclasses-1)
            locs = labels(:,class,i)';
            if any(locs(:)<0); continue; end %skip if label missing
            locs = locs(ones(size(patch,1),1),:) + patch;
            points.x(count:(count+size(locs,1)-1)) = (locs(:,1));
            points.y(count:(count+size(locs,1)-1)) = (locs(:,2));
            points.class(count:(count+size(locs,1)-1)) = uint8(class);
            points.img_index(count:(count+size(locs,1)-1)) = uint32(i);
            count=count+size(locs,1);
            p=p+size(locs,1);
            points.class_weight(class) = points.class_weight(class) + size(locs,1);
            store_joint = [store_joint; locs(:,1), locs(:,2)];
        end
        class = opts.numclasses;
        %load in background locations (i.e. negatives)
        if ~isempty(store_joint)
            idxstorejoint = (store_joint(:,1)-1-opts.padding)*opts.bbox(4) + store_joint(:,2)-opts.padding;
            idxstorejoint(idxstorejoint<=0) = [];
            idxstorejoint(idxstorejoint>(opts.bbox(4)*opts.bbox(3))) = [];
        else
            idxstorejoint = [];
        end
        
        weight = opts.numwindows-p+1;
        tempbackids = 1:(opts.bbox(3)*opts.bbox(4));
        tempbackids(idxstorejoint) =[];
        R = randperm(numel(tempbackids));
        backidx = tempbackids(R(1:weight));
        [y,x] = ind2sub([opts.bbox(4),opts.bbox(3)],backidx);
        
        points.x(count:(count + weight-1)) = x+opts.padding;
        points.y(count:(count + weight-1)) = y+opts.padding;
        points.class(count:(count + weight-1)) = uint8(class);
        points.img_index(count:(count + weight-1)) = uint32(i);
        
        count= count + weight;
        points.class_weight(class) = points.class_weight(class) + weight;        
    end    
    
    %append to points random windows within the background images
    for i = 1:total_background
        for p = 1:numbackgroundextras %add an additional 30 points per image
            x = floor(rand*opts.bbox(3)) + opts.padding + 1;
            y = floor(rand*opts.bbox(4)) + opts.padding + 1;        
            points.x(count) = x;
            points.y(count) = y;
            points.class(count) = opts.numclasses;
            points.img_index(count) = uint32(i+size(labels,3));
            points.class_weight(class) = points.class_weight(class) + 1;
            count = count +1;
        end
    end
    
    %sort points so they are quick to access
    idx = opts.bbox(4)*opts.bbox(3)*(points.img_index-1) + uint32((points.x-1)*(opts.bbox(4)+opts.padding*2) + points.y);
    [~,srtidx] = sort(idx);
    points.x = points.x(srtidx);
    points.y = points.y(srtidx);
    points.img_index = points.img_index(srtidx);
    points.class = points.class(srtidx);
    
    points.class_weight = sum(points.class_weight)./(eps+points.class_weight); %class weights used to balance the dataset
end

