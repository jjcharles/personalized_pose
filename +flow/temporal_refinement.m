%function to refine poses by comparing them against propergated
%neighbouring frames
function [refinedlocs,refinedframes,alllocs,allframeids,fromframeid,allflowq] = temporal_refinement(opts,filename,input_locs,input_frameids)

    visualise = false;
    refinedlocs = [];
    refinedframes = [];
    
    %open flow file
    if ~exist(filename.flow,'file')
        fprintf('Computing flow on the fly...\n')
        flowfile = [];
    else
        flowfile = matfile(filename.flow);
    end
    
    %open video
    vidobj = VideoReader(filename.video);
    allframeids = [];
    alllocs = [];
    fromframeid = [];
    allflowq = [];
   
    for i = 1:numel(input_frameids)
        fprintf('Propergating poses...%d of %d\n',i,numel(input_frameids));
        [locs,frameids,flowq] = track_with_flow(opts,input_locs(:,:,i),input_frameids(i),flowfile,vidobj);
        if isempty(alllocs)
            alllocs = locs;
        else
            alllocs = cat(3,alllocs,locs);
        end
        allframeids = cat(2,allframeids,frameids);
        allflowq = cat(1,allflowq,flowq);
        if ~isempty(locs)
            fromframeid = cat(2,fromframeid,ones(1,numel(frameids))*input_frameids(i));
        end
        
        
    end
    if visualise
        if ~all(alllocs(:)==-999)
            [allframeids,idsrt] = sort(allframeids);
            alllocs = alllocs(:,:,idsrt);
            show_locs(filename.video,opts.imscale,allframeids,alllocs);
        end
    end    
    %track points using optical flow
    function [locs,frameids,flowq] = track_with_flow(opts,input_locs,input_frameid,flowfile,vidobj)
     
        %check there exists a point to track
        if sum(input_locs(:)==-999) == size(input_locs,1)*size(input_locs,2)
            nopoints = true;
        else
            nopoints = false;
        end
        
        maxStepForward = min(vidobj.NumberOfFrames-input_frameid,opts.flow.stepsize);
        maxStepBackward = input_frameid - max(input_frameid-opts.flow.stepsize,1);
        
        if (input_frameid - maxStepBackward < 1) || (input_frameid + maxStepForward) > vidobj.NumberOfFrames || nopoints
            locs = [];
            frameids = [];
            flowq = [];
            return
        end
        
        %scale input locs at begining
        isinvalid = input_locs==-999;
        input_locs = (input_locs-1)/opts.imscale + 1;
        input_locs(isinvalid) = -999;
        
        img = read(vidobj,input_frameid);
        [M,N,~] = size(img);
        cellsize=3;
        gridspacing=1;
        
        total_px = M*N;
        patchwidth = opts.partdetector.model.flow.patchwidth;
        maskwidth = 2*ceil(patchwidth/16)+1;
        mask = ones(maskwidth,maskwidth);
        [mr, mc] = find(mask);
        mr = mr - ceil(maskwidth/2)+ceil(patchwidth/2);
        mc = mc - ceil(maskwidth/2)+ceil(patchwidth/2);
        idxmask = (mc-1)*patchwidth + mr;
        
        count = 1;
        for l = 1:size(input_locs,2)
            if input_locs(1,l)~=-999
                track(count).label = l;
                track(count).x = input_locs(1,l);
                track(count).y = input_locs(2,l);
                if round(track(count).x(end)) < 1; track(count).x(end) = 1; end
                if round(track(count).x(end)) > N; track(count).x(end) = N; end
                if round(track(count).y(end)) < 1; track(count).y(end) = 1; end
                if round(track(count).y(end)) > M; track(count).y(end) = M; end
                
                track(count).flowq = 0;
                track(count).idxmask = (mc-1+input_locs(1,l)-ceil(patchwidth/2))*M + mr + input_locs(2,l)-ceil(patchwidth/2);
                orig_idxmask(count).idxmask = idxmask;
                track(count).patch = getpatch([track(count).x,track(count).y],patchwidth,img);
                track(count).origsift = mexDenseSIFT(double(track(count).patch),cellsize,gridspacing);
                track(count).origsift = double(reshape(track(count).origsift,patchwidth^2,[]));
                count= count + 1;
            end
        end
        %track forward
        for i = 2:(maxStepForward+1)
            flowval = flowfile.flow(:,:,:,input_frameid+i-2);
            flowval = flow.uncompress_flow_minmax(flowval,flowfile.minmax(:,:,input_frameid+i-2));
            current_img = read(vidobj,input_frameid + i -1);
            for l = 1:numel(track)
                track(l).x(end+1) = track(l).x(end) + flowval(round(track(l).y(end)),round(track(l).x(end)),1);
                track(l).y(end+1) = track(l).y(end) + flowval(round(track(l).y(end)),round(track(l).x(end-1)),2);
                if round(track(l).x(end)) < 1; track(l).x(end) = 1; end
                if round(track(l).x(end)) > N; track(l).x(end) = N; end
                if round(track(l).y(end)) < 1; track(l).y(end) = 1; end
                if round(track(l).y(end)) > M; track(l).y(end) = M; end

                
                %compute matching mask for matching term I DONT TRACK THE
                %MASK FOR SPEED PURPOSES
%                 track(l).idxmask(:,end+1) = track(l).idxmask(:,end) + (round(flowval(track(l).idxmask(:,end)))-1)*M + (round(flowval(track(l).idxmask(:,end)+total_px))-1);
%                 track(l).idxmask(track(l).idxmask<1) = 1;
%                 track(l).idxmask(track(l).idxmask>total_px) = total_px;
                
                %get matching term
                current_patch = getpatch([track(l).x(end),track(l).y(end)],patchwidth,current_img);
                current_sift = mexDenseSIFT(double(current_patch),cellsize,gridspacing);
                current_sift = double(reshape(current_sift,patchwidth^2,[]));
                track(l).flowq = cat(1,track(l).flowq,mean(sum(((track(l).origsift(orig_idxmask(l).idxmask,:) - current_sift(orig_idxmask(l).idxmask,:)).^2)./(eps+(track(l).origsift(orig_idxmask(l).idxmask,:) + current_sift(orig_idxmask(l).idxmask,:))),2))); 
            end
        end
        
        %trackbackward
        for i = 2:(maxStepBackward+1)
            flowval = flowfile.flow(:,:,:,input_frameid-i+1);
            flowval = flow.uncompress_flow_minmax(flowval,flowfile.minmax(:,:,input_frameid-i+1));
            flowval = flow.get_backwards_flow(flowval);
            current_img = read(vidobj,input_frameid - i +1);
            for l = 1:numel(track)
                track(l).x = cat(2,track(l).x(1) + flowval(round(track(l).y(1)),round(track(l).x(1)),1),track(l).x);
                track(l).y = cat(2,track(l).y(1) + flowval(round(track(l).y(1)),round(track(l).x(2)),2),track(l).y);
                if round(track(l).x(1)) < 1; track(l).x(1) = 1; end
                if round(track(l).x(1)) > N; track(l).x(1) = N; end
                if round(track(l).y(1)) < 1; track(l).y(1) = 1; end
                if round(track(l).y(1)) > M; track(l).y(1) = M; end
                
%                 I DONT TRACK THE MASK FOR SPEED PURPOSES
%                 track(l).idxmask = cat(2,track(l).idxmask(:,1) + (round(flowval(track(l).idxmask(:,1)))-1)*M + (round(flowval(track(l).idxmask(:,1)+total_px))-1),track(l).idxmask);
%                 track(l).idxmask(track(l).idxmask<1) = 1;
%                 track(l).idxmask(track(l).idxmask>total_px) = total_px;
                
                %get matching term
                current_patch = getpatch([track(l).x(1),track(l).y(1)],patchwidth,current_img);
                current_sift = mexDenseSIFT(double(current_patch),cellsize,gridspacing);
                current_sift = double(reshape(current_sift,patchwidth^2,[]));
                track(l).flowq = cat(1,mean(sum(((track(l).origsift(orig_idxmask(l).idxmask,:) - current_sift(orig_idxmask(l).idxmask,:)).^2)./(eps+(track(l).origsift(orig_idxmask(l).idxmask,:) + current_sift(orig_idxmask(l).idxmask,:))),2)),track(l).flowq);
%                  ll = ones(M,N);
%                 ll(track(l).idxmask(:,1)) = 0;
%                 imagesc(ll); axis image; pause
            end
        end
        
        frameids = (input_frameid-maxStepBackward):(input_frameid+maxStepForward);
        locs = -999*ones(2,size(input_locs,2),numel(frameids));
        flowq = inf*ones(numel(frameids),size(input_locs,2));
        
        for l = 1:numel(track)
            locs(1,track(l).label,:) = permute(track(l).x,[1 3 2]);
            locs(2,track(l).label,:) = permute(track(l).y,[1 3 2]);
            flowq(:,track(l).label) = track(l).flowq;
        end
        
        %scale output locs
        isinvalid = locs==-999;
        locs = (locs-1)*opts.imscale + 1;
        locs(isinvalid) = -999;