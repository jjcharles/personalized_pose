%function to extract feature from images given data points and offset
function feature = get_feature(opts,WI,data,images,channel,func_type,offset)
    func = oforest.func_pointer(func_type);
  
    data_img_index = double(data.img_index(WI));
    data_x = double(data.x(WI));    
    data_y = double(data.y(WI));
    if size(WI,2) == 1
        data_x = data_x(:);
        data_y = data_y(:);
        data_img_index = data_img_index(:);
    end

    if func_type == 1 %unary function
        %sample offsets
        index1 =  uint32((double(opts.imgwidth*opts.imgheight))*((data_img_index-1)*opts.numchannels + (channel-1))  + (double(opts.imgheight)*(data_x+offset(1,ones(1,size(WI,2)))-1)) + (data_y+offset(1,2*ones(1,size(WI,2)))));
        feature = int16(images(index1(:))');    
    else %binary function
        %sample offsets
        index1 =  uint32((double(opts.imgwidth*opts.imgheight))*((data_img_index-1)*opts.numchannels + (channel-1))  + (double(opts.imgheight)*(data_x+offset(1,ones(1,size(WI,2)))-1)) + (data_y+offset(1,2*ones(1,size(WI,2)))));
        index2 =  uint32((double(opts.imgwidth*opts.imgheight))*((data_img_index-1)*opts.numchannels + (channel-1))  + (double(opts.imgheight)*(data_x+offset(1,3*ones(1,size(WI,2)))-1)) + (data_y+offset(1,4*ones(1,size(WI,2)))));
        value1 = images(index1(:));
        value2 = images(index2(:));
        feature = func(int16(value1),int16(value2))';
    end
    