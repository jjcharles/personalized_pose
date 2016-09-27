%function to remove joint detections based on foreground background
%classification
%allows input of seperate training and testing data
function detections_test = foreground_background_eval(opts,filename,detections_train,detections_test,fieldname)

frameids = detections_train.training.frameids;
locs = detections_train.training.locs;
total_frames = numel(frameids);
check_patch_width = 20;
numclasses = size(locs,2);
load(filename.patches);
pos_avg = -ones(numclasses,total_frames);
neg_avg = zeros(1,total_frames);
vidobj = VideoReader(filename.video);
        
for i = 1:total_frames
    fprintf('training evaluator from frame %d of %d f/g evaluation\n',i,total_frames);
    framenumber = frameids(i);
    img = imresize(read(vidobj,framenumber),opts.imscale);
    
    %build positive patch database
    cpimg = double(features.cp(opts,img,videoToColor));
    prob_foreground = sum(cpimg(:,:,1:2),3)./(sum(cpimg,3));
    for l = 1:numclasses
        if locs(1,l,i)~=-999
            %get tiny patches to build pdfs of positives
            patch = getpatch(locs(:,l,i),check_patch_width,prob_foreground);
            pos_avg(l,i) = mean(patch(:));
        end
    end
    %get negative data
    neg_avg(i) = mean(prob_foreground(prob_foreground(:)<0.7)); %use 0.7 to have a margin of 0.2 (0.7 = 0.2 + 0.5)
end

%classify joints as either correct or incorrect using naive bayes
%first build the pos and neg distributions
histfilt = fspecial('gaussian',3,3/6);
numbins = 10;
bins = linspace(0,1,numbins+1);
pdf_pos = zeros(numel(bins),numclasses);
for l = 1:numclasses
    class_pos = pos_avg(l,:);
    class_pos(pos_avg(l,:)<0) = [];
    pdf_pos(:,l) = histc(class_pos',bins); 
    pdf_pos(:,l) = imfilter(pdf_pos(:,l),histfilt(:,ceil(size(histfilt,1)/2)),'replicate');
    pdf_pos(:,l) = bsxfun(@rdivide,pdf_pos(:,l),sum(pdf_pos(:,l))+eps);
end

pdf_neg = histc(neg_avg',bins); 
pdf_neg = imfilter(pdf_neg,histfilt(:,ceil(size(histfilt,1)/2)),'replicate');
pdf_neg = bsxfun(@rdivide,pdf_neg,sum(pdf_neg)+eps);

%classify
frameids = detections_test.(fieldname).frameids;
locs = detections_test.(fieldname).locs;
total_frames = numel(frameids);
pos_avg = -ones(numclasses,total_frames);
        
for i = 1:total_frames
    fprintf('evaluating frame %d of %d f/g evaluation\n',i,total_frames);
    framenumber = frameids(i);
    img = imresize(read(vidobj,framenumber),opts.imscale);
    
    %build positive patch database
    cpimg = double(features.cp(opts,img,videoToColor));
    prob_foreground = sum(cpimg(:,:,1:2),3)./(sum(cpimg,3));
    for l = 1:numclasses
        if locs(1,l,i)~=-999
            %get tiny patches to build pdfs of positives
            patch = getpatch(locs(:,l,i),check_patch_width,prob_foreground);
            pos_avg(l,i) = mean(patch(:));
        end
    end
end

for l = 1:numclasses
    %check naive bayes classification of patch
    [~,indpos] = histc(pos_avg(l,:),bins);
    indpos(indpos==0) = 1;
    class = pdf_pos(indpos,l) > pdf_neg(indpos);

    removeid = squeeze(pos_avg(l,:)<0) | ~class';
    locs(:,l,removeid) = -999;
end

%set annotation
remid = sum(sum(locs==-999))==(size(locs,1)*size(locs,2));
locs(:,:,remid) = [];
frameids(remid) =[];
    
detections_test.(fieldname).locs = locs;
detections_test.(fieldname).frameids = frameids;