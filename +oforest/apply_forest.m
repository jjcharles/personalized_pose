%function to apply forest to a frame
function [locs,dist,conf,leafids] = apply_forest(omodel,frame,bbox,islocs_needed,filter_width)
    if ~exist('filter_width','var')
        filter_width = 8;
    end

    if ~exist('islocs_needed','var')
        islocs_needed = true;
    end
    
    %check for correct padding
    omodel.opts.model.windowwidth  = max(omodel.opts.model.windows.widths);
    omodel.opts.model.padding = ceil(omodel.opts.model.windowwidth/2) + 1;
    frame = imcrop(frame,bbox);
    bbox(1) = bbox(1) + omodel.opts.model.padding;
    bbox(2) = bbox(2) + omodel.opts.model.padding;
    conf = zeros(1,omodel.opts.model.numclasses-1);
    
    save_bbox = bbox;
    bbox(1:2) = 1+ omodel.opts.model.padding;
    frame_pad = padarray(frame,[omodel.opts.model.padding omodel.opts.model.padding],0,'both');
    if islocs_needed
        dist = zeros(bbox(4)*bbox(3),omodel.opts.model.numclasses);
    else
        dist = [];
    end
    leafids = zeros(bbox(4),bbox(3),numel(omodel.forestmat));
    
    for f = 1:numel(omodel.forestmat);
        [tempdist,templeafid] = mxclassify(omodel.opts.model.numchannels,...
            bbox(1),bbox(2),bbox(3),bbox(4),...
            double(omodel.forestmat{f}),double(frame_pad),...
            omodel.opts.model.numclasses);
        leafids(:,:,f) = reshape(templeafid,bbox(4),bbox(3));

        if islocs_needed
            dist = dist + tempdist;
        end
    end

    dist = dist/numel(omodel.forestmat);
    locs = zeros(2,omodel.opts.model.numclasses-1);
    
    if islocs_needed 
        filt = fspecial('gaussian',filter_width*6,filter_width);
        dist = reshape(dist,[bbox(4),bbox(3),omodel.opts.model.numclasses]);
        dist = imfilter(dist,filt,0)/numel(omodel.forestmat);
        if isfield(omodel,'prior')
            dist = bsxfun(@rdivide,dist,sum(sum(dist)));
            dist = (dist(:,:,1:(omodel.opts.model.numclasses-1))+0.0001).*omodel.prior;
        end

    
        for c = 1:(omodel.opts.model.numclasses-1)
            [my, idxy]= max(dist(:,:,c)); %take point of maximum confidence
            [mx,x] = max(my);

            y = idxy(x);
            locs(:,c) = [x; y];
            conf(c) = mx;
        end

        locs = bsxfun(@plus,locs,[save_bbox(1);save_bbox(2)]-1-omodel.opts.model.padding);
    end