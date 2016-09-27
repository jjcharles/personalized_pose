function [ train_data_file, test_data_file] = setupTrainingDataCropped(cnnopts,exp_name,videoname,videoFilename,trainFrameids,trainLocs,testFrameids,testLocs,imscale,bbWidth,bbHeight)
%SETUPTRAININGDATACROPPED This function sets up the training material
    % creates training image files and produces the required training and
    % testing text files for training the CNN
    %
    % This cropped version of setupTrainingData, will train from patches of
    % images of a set size, cropped out of the training window. e.g. 256 by
    % 256 windows around the persons joints, some scale variation is also
    % added. 
   
    % bbWidth - bounding box Width
    % bbHeight - bounding box Height (we crop around head location, if no
    % head location then we crop around mean joint location)
    
    visualise = false;
    
    numScales = 5;
    numNegs = 10;
    scaleRange = [0.8 1.2]; %this is the scale range augmentation
    bboxRange = [-50 50]; %cropping range augmentation in pixels
    
    
    %make sure locs are integer
    trainLocs = round(trainLocs);
    testLocs = round(testLocs);
    
    %load video
    vidobj = VideoReader(videoFilename);
    
    %setup folders
    ramdisk_folder = check_dir(cnnopts.finetune.ramdisk_folder);
    train_folder = check_dir(sprintf('%s%s/%s/train/',ramdisk_folder,exp_name,videoname),true);
    test_folder = check_dir(sprintf('%s%s/%s/test/',ramdisk_folder,exp_name,videoname),true);
    train_data_file = sprintf('%s%s/%s/train_files.txt', ramdisk_folder,exp_name,videoname);
    test_data_file = sprintf('%s%s/%s/test_files.txt', ramdisk_folder,exp_name,videoname);

    %shuffel the images
    shuffle_train_id = randperm(numel(trainFrameids));
    shuffle_test_id = randperm(numel(testFrameids));
    trainFrameids = trainFrameids(shuffle_train_id);
    testFrameids = testFrameids(shuffle_test_id);
    trainLocs = trainLocs(:,:,shuffle_train_id);
    testLocs = testLocs(:,:,shuffle_test_id);

    %loop through training data and save info
    img_filenames = cell(numel(trainFrameids)*(numScales+numNegs),1);
    tempTrainLocs = [];

    imgCount = 1;
    for i = 1:numel(trainFrameids)
        fprintf('setting up training file %d of %d\n',i,numel(trainFrameids));
        frameid = trainFrameids(i);
        imgOrig = read(vidobj,frameid);
        imgOrig = imresize(imgOrig,imscale);
        
        %get standard bounding box from head position or if not available
        %use mean joint locations
        if trainLocs(1,1,i)~=-999
            R = round(bbHeight*0.2);
            C = round(bbWidth*0.5);
            top = trainLocs(2,1,i)-R;
            left = trainLocs(1,1,i)-C;
            standardBBox = [left top bbWidth bbHeight];
        else %use mean joint location
            R = round(bbHeight*0.4);
            C = round(bbWidth*0.5);
            goodIDs = trainLocs(1,:,i)~=-999;
            anchorLoc = round(mean(trainLocs(:,goodIDs,i),2));            
            top = anchorLoc(2)-R;
            left = anchorLoc(1)-C;
            standardBBox = [left top bbWidth bbHeight];
        end
        standardBBox(1) = max(standardBBox(1),1);
        standardBBox(2) = max(standardBBox(2),2);
        
        for s = 1:numScales
            img = imgOrig;
            bbox = standardBBox;
            if s == 1
                scale = 1;
                shift = [0 0];
            else
                scale = scaleRange(1) + (scaleRange(2)-scaleRange(1))*rand;
                shift = rand(1,2)*(bboxRange(2)-bboxRange(1))+bboxRange(1);
            end
            
            %scale the bbox and add a shift
            bbox(3:4) = bbox(3:4)*scale;
            bbox(1:2) = bbox(1:2) + shift; 
            bbox = round(bbox);

            %pad the image for cropping
            diff = max(size(img,2)-bbox(1),size(img,1)-bbox(2));
            if diff > 0
                pad = diff*2;
            else
                pad = 10;
            end
            img = padarray(img,[pad,pad],0,'both');
            bbox(1:2) = bbox(1:2) + pad;
            datax = bbox(1):(bbox(1)+bbox(3)-1);
            datay = bbox(2):(bbox(2)+bbox(4)-1);
            img = img(datay,datax,:);
            
            %resize crop to CNN input dimensions
            img = imresize(img,cnnopts.finetune.dims);
            
            %adjust joint locations to match cropped image
            tempLocs = trainLocs(:,:,i);
            remid = tempLocs==-999;
            tempLocs = bsxfun(@minus,tempLocs+pad,bbox(1:2)'-1);
            scalex = bbox(3)/cnnopts.finetune.dims(1);
            scaley = bbox(4)/cnnopts.finetune.dims(2);
            tempLocs = bsxfun(@rdivide,tempLocs,[scalex;scaley]);
            tempLocs(remid) = -999;
            tempTrainLocs = cat(3,tempTrainLocs, tempLocs);

            img_filenames{imgCount} = sprintf('%sframe_%06d.jpg',train_folder,imgCount);
            imwrite(img,img_filenames{imgCount});
            imgCount = imgCount + 1;
        end
        
        %collect negatives
        for n = 1:numNegs
            img = imgOrig;
            bbox = [1 1 bbWidth bbHeight];
            
            %scale the bbox and add a shift
            scale = scaleRange(1) + (scaleRange(2)-scaleRange(1))*rand;
            bbox(3:4) = bbox(3:4)*scale;
            shift = rand(1,2);
            shift(1) = shift(1)*(size(img,2)-bbox(3)) + 1;
            shift(2) = shift(2)*(size(img,1)-bbox(4)) + 1;
            bbox(1:2) = bbox(1:2) + shift;
            
            bbox = round(bbox);
            
            %pad the image for cropping
            diff = max(size(img,2)-bbox(1),size(img,1)-bbox(2));
            if diff > 0
                pad = diff*2;
            else
                pad = 10;
            end
            img = padarray(img,[pad,pad],0,'both');
            bbox(1:2) = bbox(1:2) + pad;
            datax = bbox(1):(bbox(1)+bbox(3)-1);
            datay = bbox(2):(bbox(2)+bbox(4)-1);
            img = img(datay,datax,:);
            
            %resize crop to CNN input dimensions
            img = imresize(img,cnnopts.finetune.dims);
            
            %adjust joint locations to match cropped image
            tempLocs = trainLocs(:,:,i);
            remid = tempLocs==-999;
            tempLocs = bsxfun(@minus,tempLocs+pad,bbox(1:2)'-1);
            scalex = bbox(3)/cnnopts.finetune.dims(1);
            scaley = bbox(4)/cnnopts.finetune.dims(2);
            tempLocs = bsxfun(@rdivide,tempLocs,[scalex;scaley]);
            tempLocs(remid) = -999;
            tempTrainLocs = cat(3,tempTrainLocs, tempLocs);

            img_filenames{imgCount} = sprintf('%sframe_%06d.jpg',train_folder,imgCount);
            imwrite(img,img_filenames{imgCount});
            imgCount = imgCount + 1;
        end
    end
    trainLocs = round(tempTrainLocs);

    
    produceDataFile(train_data_file,img_filenames,trainLocs,[1 1 bbWidth bbHeight]);
    
    if visualise
        figure
        for i = 1:numel(img_filenames)
            clf
            img = imread(img_filenames{i});
            imagesc(img); axis image;
            hold on
            plot_skeleton(trainLocs(:,:,i),[],[]);
            pause(0.1)
            drawnow
        end
    end

    %loop through testing data and save
    img_filenames = cell(numel(testFrameids),1);
    for i = 1:numel(testFrameids)
        fprintf('setting up tetsing file %d of %d\n',i,numel(testFrameids));
        frameid = testFrameids(i);
        img = read(vidobj,frameid);
        img = imresize(img,cnnopts.finetune.dims);
        img_filenames{i} = sprintf('%sframe_%06d.jpg',test_folder,i);
        imwrite(img,img_filenames{i});
    end    
    produceDataFile(test_data_file,img_filenames,testLocs,[1 1 bbox(3) bbox(4)]);
    
%-----------------------------------MAIN FUNCTION ENDS ----------------------------------------


    %function to produce data file to hold image data
    function produceDataFile(filename,img_filenames,locs,crop_coords)
        fid = fopen(filename,'w');
        str_crop_coords = sprintf('%d,%d,%d,%d 0',crop_coords(1),crop_coords(2),crop_coords(3),crop_coords(4));
        randIdx = randperm(numel(img_filenames));
        for i = 1:numel(img_filenames)
            idx = randIdx(i);
            %write info to file
            fprintf(fid,'%s ',img_filenames{idx});
            templocs = locs(:,:,idx);
            for l = 1:numel(templocs)
                fprintf(fid,'%d',templocs(l));
                if l == numel(templocs)
                    fprintf(fid, ' %s',str_crop_coords); %put in crop coordinates
                else
                    fprintf(fid,',');
                end
            end

            if i~=numel(img_filenames)
                fprintf(fid,'\n');
            end
        end
        fclose(fid);
    
    

