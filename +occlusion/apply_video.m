function [ isoccluded ] = apply_video( opts, occlusion_model, videofilename, frameids, locs,labels)
%APPLY_VIDEO apply trained occlusion model to joint locations in a video

    vidobj = VideoReader(videofilename);
    %get list of labels we have an occlusion model for
    occlusion_labels = cat(1,occlusion_model(:).label);
    ia = ismember(occlusion_labels,labels);
    assert(any(ia~=0),'no occlusion model for that input label');
    
    remid= locs==-999;
    locs = round(locs*opts.imscale);
    locs(locs==0) = 0;
    locs(remid) = -999;
    
    %setup output
    isoccluded = zeros(numel(frameids),numel(labels));
    for i = 1:numel(frameids)
        fprintf('applying occlusion detector in frame %d of %d\n',i,numel(frameids));
        framenumber = frameids(i);
        img = imresize(read(vidobj,framenumber),opts.imscale);
        for l = 1:numel(labels)
            %skip joint if not present
            if locs(1,labels(l),i)==-999
                continue
            else
                isoccluded(i,l) = occlusion.apply_frame(occlusion_model(occlusion_labels==labels(l)),locs(:,labels(l),i),img);
            end
        end
    end
    isoccluded = logical(isoccluded);
end

