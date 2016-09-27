%returns both hog and rgb patches with rotation augmentation
function [hogpatches,rgbpatches, labels] = get_training_patches(opts,videofilename,frameids,locs)
%GET_TRAINING_PATCHES_HOG gets patches of image for training an occlusion
%detector

    %get size of hog patches
    dummypatch = single(round(rand(opts.occlusion.patchwidth,opts.occlusion.patchwidth,3)*255));
    dummyhog = features.hog(dummypatch,opts.occlusion.hog_cell_size);
    hogwidth = size(dummyhog,1);
    patchwidth = ceil(opts.occlusion.patchwidth/opts.occlusion.rgbsubsamp);
    
    rgbpatches = zeros(numel(frameids)*(opts.occlusion.numnegperim+numel(opts.occlusion.rotations)),patchwidth*patchwidth*3);
    hogpatches = zeros(numel(frameids)*(opts.occlusion.numnegperim+numel(opts.occlusion.rotations)),hogwidth*hogwidth*32);
    labels = zeros(1,numel(frameids)*(opts.occlusion.numnegperim+numel(opts.occlusion.rotations)));
    vidobj = VideoReader(videofilename);
    count = 1;
    
    %setup rotation matrices
    R = zeros(2,2,numel(opts.occlusion.rotations));
    for r = 1:numel(opts.occlusion.rotations)
        R(:,:,r) = [cos(-opts.occlusion.rotations(r)*(2*pi/360)), -sin(-opts.occlusion.rotations(r)*(2*pi/360)); sin(-opts.occlusion.rotations(r)*(2*pi/360)), cos(-opts.occlusion.rotations(r)*(2*pi/360))];
    end
    
    tempim = imresize(read(vidobj,1),opts.imscale);
    [M,N,~] = size(tempim);
    
    for i = 1:numel(frameids)
        fprintf('getting training hog/rgb patches for occlusion model %d of %d\n',i,numel(frameids));
        origim = imresize(read(vidobj,frameids(i)),opts.imscale);
        %pad image
        origim = padarray(origim,[opts.occlusion.patchwidth,opts.occlusion.patchwidth],0,'both');
        templocs = locs(:,i) + opts.occlusion.patchwidth;
        bigpatch = getpatch(templocs,opts.occlusion.patchwidth*2+1,origim);
        
        
            
        for r = 1:numel(opts.occlusion.rotations)
            img = imrotate(bigpatch,opts.occlusion.rotations(r),'bicubic','crop');
            templocs = [opts.occlusion.patchwidth,opts.occlusion.patchwidth]+1;
            
            rgbpatch = getpatch(templocs,opts.occlusion.patchwidth,img);
%             imagesc(rgbpatch); axis image; drawnow
            
%             imagesc(img)
%             hold on
%             axis image
%             plot(templocs(1),templocs(2),'bo','markerfacecolor','b')
%             pause
% clf
            %positive
            temphog = single(features.hog(rgbpatch,opts.occlusion.hog_cell_size));
            hogpatches(count,:) =  temphog(:)';
            labels(count) = 1;
            
            rgbpatch = rgbpatch(1:opts.occlusion.rgbsubsamp:end,1:opts.occlusion.rgbsubsamp:end,:);
            temprgb = uint8(rgbpatch); 
            rgbpatches(count,:) = temprgb(:)';
        
            count = count + 1;
        end
        
        %negative
        for n = 1:opts.occlusion.numnegperim
            xtemp = floor((size(origim,2)-1)*rand) + 1;
            ytemp = floor((size(origim,2)-1)*rand) + 1;
            rgbpatch = getpatch([xtemp;ytemp],opts.occlusion.patchwidth,origim);
%             rgbpatch = getpatch(locs(:,i)+round(opts.occlusion.negradius + opts.occlusion.negradiusmult*randn),opts.occlusion.patchwidth,img);
            temphog = single(features.hog(rgbpatch,opts.occlusion.hog_cell_size)); 
            hogpatches(count,:) = temphog(:)';
            labels(count) = 0;
            count = count + 1;
        end
    end

end

