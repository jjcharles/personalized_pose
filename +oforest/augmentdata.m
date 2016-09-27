%augment the training data by adding in some rotations
function [images,labels] = augmentdata(input_images,input_labels,rotations)

    images = repmat(uint8(0),[size(input_images,1),size(input_images,2),size(input_images,3),size(input_images,4)*(1+numel(rotations))]);
    labels = zeros(size(input_labels,1),size(input_labels,2),size(input_labels,3)*(1+numel(rotations)));
    [m,n,~,~,] = size(input_images);
    count = 1;

    for r = 1:numel(rotations)
        images(:,:,:,(((r-1)*size(input_images,4))+1):((((r-1)*size(input_images,4)))+size(input_images,4))) = imrotate(input_images,rotations(r),'bicubic','crop');
        
        %rotate the labels
        %setup rotation matrix for label locations
        rot_mat = [cos(-rotations(r)*(2*pi/360)), -sin(-rotations(r)*(2*pi/360)); sin(-rotations(r)*(2*pi/360)), cos(-rotations(r)*(2*pi/360))];
       
        for i = 1:size(input_labels,3)
            templabels = input_labels(:,:,i);
            templabels = bsxfun(@minus,templabels,[n/2;m/2]);
            templabels = rot_mat*templabels;
            templabels  = bsxfun(@plus,templabels,[n/2;m/2]);
            templabels(input_labels(:,:,i)<1) = -999;
            templabels(:,min(templabels)<1) = -999;
            
            labels(:,:,count) = templabels;
            count = count + 1;
        end
    end
    
    r = numel(rotations)+1;
    images(:,:,:,(((r-1)*size(input_images,4))+1):((((r-1)*size(input_images,4)))+size(input_images,4))) = input_images;
    labels(:,:,(((r-1)*size(input_images,4))+1):((((r-1)*size(input_images,4)))+size(input_images,4))) = input_labels;
    
    