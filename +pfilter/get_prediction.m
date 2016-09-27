%returns predictions from particles

function [P, conf] = get_prediction(particle,img_size)

    x = cat(1,particle(:).x);
    y = cat(1,particle(:).y);
    
    x = round(x);
    y = round(y);
    
    bbox_in = [min(x),min(y),max(x)-min(x)+1,max(y)-min(y)+1];
    x = x-bbox_in(1)+1;
    y = y-bbox_in(2)+1;
    
    pdf = zeros(bbox_in(4),bbox_in(3));
    ind = bbox_in(4)*(x-1) + y;
    [ind,idx]  = sort(ind);
    pdf(ind) = 1;
    
    filt = fspecial('gaussian',round(mean(bbox_in(3:4))*0.5)*3,round(mean(bbox_in(3:4))*0.5)*3/6);
    pdff = imfilter(pdf,filt,0);
    [my,idxy] = max(pdff);
    [~,idxx] = max(my);
    xout = idxx(1);
    yout = idxy(idxx(1));
    P = [xout+bbox_in(1)-1, yout+bbox_in(2)-1];
    
    %output confidence map if img size is given
    if nargin > 1
        conf =  zeros(img_size);
        conf(bbox_in(2):(bbox_in(2)+bbox_in(4)-1),bbox_in(1):(bbox_in(1)+bbox_in(3)-1))= pdf;
        conf = imfilter(conf,filt);
    else
        conf = [];
    end
    