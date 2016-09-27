%computer segcp feature from input rgb and face and torso patches and
%segmentation
function [feat,colour_hist] = cp(opts,rgbimg,patches)    
    if isfield(patches{1},'colourhist')
        colour_hist = patches{1}.colourhist;
    else
        ref.face = [];
        ref.torso = [];
        ref.back = [];
        ref.backmask = [];
        for template_id = 1:numel(patches)
            if (~isempty(patches{template_id}.face))
                face = patches{template_id}.face;
                torso = patches{template_id}.torso;

                face = reshape(face,[size(face,1)*size(face,2),1,3]);
                torso = reshape(torso,[size(torso,1)*size(torso,2),1,3]);

                ref.face = cat(1,ref.face, face);
                ref.torso = cat(1,ref.torso, torso);   
                if isfield(patches{template_id},'backmask')
                    back = patches{template_id}.back;
                    back = reshape(back,[size(back,1)*size(back,2),1,3]);
                    ref.back = cat(1,ref.back,back);
                    backmask = patches{template_id}.backmask;
                    backmask = reshape(backmask,[size(backmask,1)*size(backmask,2),1,1]);
                    ref.backmask = cat(1,ref.backmask,backmask);
                end
            end
        end

        MBf = (sum(ref.face,3)~=0);
        MBt = (sum(ref.torso,3)~=0);
        ref.face = uint8(ref.face);
        ref.torso = uint8(ref.torso);
        colour_hist{1} = smooth_normalise_hist(opts,mre_rgbhistogram(ref.face,opts.colourhist.bits,MBf));
        colour_hist{2} = smooth_normalise_hist(opts,mre_rgbhistogram(ref.torso,opts.colourhist.bits,MBt));

        %compute posterior image
        if isfield(patches{template_id},'backmask')
            colour_hist{3} = smooth_normalise_hist(opts, mre_rgbhistogram(ref.back,opts.colourhist.bits,logical(ref.backmask)));
        else
            seg = true(size(rgbimg,1),size(rgbimg,2));
            seg(:,round(size(rgbimg,2)/2):end) = false;
            colour_hist{3} = smooth_normalise_hist(opts, mre_rgbhistogram(rgbimg,opts.colourhist.bits,~logical(seg)));
        end
    end
    
    C = zeros(size(rgbimg));
    N = sum(cat(4,colour_hist{:}),4);
    for i = 1:3
        colour_hist{i} = colour_hist{i}./N;
        C(:,:,i) = mre_rgblookup(rgbimg, colour_hist{i});
    end   
    

    img_feat = bsxfun(@rdivide,C,sum(C,3)+eps); 
    feat = uint8(img_feat*255);
    
    
    function histogram = smooth_normalise_hist(opts, histogram)
        histogram=histogram+1;
        histogram = gauss3d(histogram,opts.colourhist.smoothvariance,0);
        histogram=histogram/sum(histogram(:));