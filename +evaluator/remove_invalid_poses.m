%function to identify frames where the pose estimates are not valid, ie.
%they have limb lengths greater than normal
function detections = remove_invalid_poses(detections,field_name,current_detections)

    shoulder_to_shoulder = sqrt(sum(  (current_detections.manual.locs(:,[6],:)-current_detections.manual.locs(:,[7],:)).^2));
    %remove out of range (these values come from some joints having -999)
    idrem = current_detections.manual.locs(1,6,:)==-999;
    idrem = idrem | current_detections.manual.locs(1,7,:)==-999;
    shoulder_to_shoulder(:,:,idrem) = [];
    shoulder_to_shoulder = mean(shoulder_to_shoulder(:));
    
    %use those poses in the manual annotations to define a distribution over limb length distances
    shoulder_to_head = sqrt(sum((bsxfun(@minus,current_detections.manual.locs(:,[6,7],:),current_detections.manual.locs(:,1,:))).^2));
    %remove out of range (these values come from some joints having -999)
    idrem = current_detections.manual.locs(1,6,:)==-999;
    idrem = idrem | current_detections.manual.locs(1,7,:)==-999;
    idrem = idrem | current_detections.manual.locs(1,1,:)==-999;
    shoulder_to_head(:,:,idrem) = [];
    shoulder_to_head = shoulder_to_head(:)/shoulder_to_shoulder;
    
    elbow_to_shoulder = sqrt(sum(  (current_detections.manual.locs(:,[6,7],:)-current_detections.manual.locs(:,[4 ,5],:)).^2));
    %remove out of range (these values come from some joints having -999)
    idrem = current_detections.manual.locs(1,6,:)==-999;
    idrem = idrem | current_detections.manual.locs(1,7,:)==-999;
    idrem = idrem | current_detections.manual.locs(1,4,:)==-999;
    idrem = idrem | current_detections.manual.locs(1,5,:)==-999;
    elbow_to_shoulder(:,:,idrem) = [];
    elbow_to_shoulder = elbow_to_shoulder(:)/shoulder_to_shoulder;
        
    wrist_to_elbow = sqrt(sum(  (current_detections.manual.locs(:,[2,3],:)-current_detections.manual.locs(:,[4 ,5],:)).^2));
%     wrist_to_elbow = wrist_to_elbow(:);
%     wrist_to_elbow(wrist_to_elbow==0) = [];
    %remove out of range (these values come from some joints having -999)
    idrem1 = current_detections.manual.locs(1,2,:)==-999;
    idrem1 = idrem1 | current_detections.manual.locs(1,4,:)==-999;
    idrem2 = current_detections.manual.locs(1,3,:)==-999;
    idrem2 = idrem2 | current_detections.manual.locs(1,5,:)==-999;
    wrist_to_elbow(1,1,find(idrem1)) = -999;
    wrist_to_elbow(1,2,find(idrem2)) = -999;
    wrist_to_elbow = wrist_to_elbow(:);
    wrist_to_elbow(wrist_to_elbow==-999) = [];
    wrist_to_elbow = wrist_to_elbow(:)/shoulder_to_shoulder;
    
    thresh = 0; %all invalid if less than this probability of occuring
    numbins = 40;
    filt = fspecial('gaussian',10,10/6);
    reg = 0;
    we_bins = linspace(0,2*max(wrist_to_elbow),numbins+1);
    pdf_we = histc(wrist_to_elbow,we_bins);
    pdf_we(pdf_we>0) = 1;
    pdf_we = pdf_we + reg;
    pdf_we = imfilter(pdf_we,filt,'replicate');
    pdf_we = (pdf_we)/sum(pdf_we+eps);
    
    sh_bins = linspace(0,2*max(shoulder_to_head),numbins+1);
    pdf_sh = histc(shoulder_to_head,sh_bins);
    pdf_sh(pdf_sh>0) = 1;
    pdf_sh = pdf_sh + reg;
    pdf_sh = imfilter(pdf_sh,filt,'replicate');
    pdf_sh = (pdf_sh)/sum(pdf_sh+eps);
    
    es_bins = linspace(0,2*max(elbow_to_shoulder),numbins+1);
    pdf_es =  histc(elbow_to_shoulder,es_bins);
    pdf_es(pdf_es>0) = 1;
    pdf_es = pdf_es + reg;
    pdf_es = imfilter(pdf_es,filt,'replicate');
    pdf_es = (pdf_es)/sum(pdf_es+eps);
    
    if 0
        figure
        subplot(131)
        plot(we_bins,pdf_we); title('elbow to wrist');
        subplot(132)
        plot(sh_bins,pdf_sh);title('shoulder to head');
        subplot(133)
        plot(es_bins,pdf_es);title('elbow to shoulder');
    end
    
    
    %for each frame look up the probability 
    shoulder_to_head = sqrt(sum((bsxfun(@minus,detections.(field_name).locs(:,[6],:),detections.(field_name).locs(:,1,:))).^2));
    shoulder_to_head = shoulder_to_head(:)/shoulder_to_shoulder;
    
    elbow_to_shoulder = sqrt(sum(  (detections.(field_name).locs(:,[6],:)-detections.(field_name).locs(:,[4],:)).^2));
    elbow_to_shoulder = elbow_to_shoulder(:)/shoulder_to_shoulder;
    
    wrist_to_elbow = sqrt(sum(  (detections.(field_name).locs(:,[2],:)-detections.(field_name).locs(:,[4],:)).^2));
    wrist_to_elbow = wrist_to_elbow(:)/shoulder_to_shoulder;
    
    [~,ind] = histc(shoulder_to_head,sh_bins);
    badbins = find(pdf_sh<thresh);
    remove_sh = ismember(ind,badbins) | shoulder_to_head > sh_bins(end);
    
    [~,ind] = histc(elbow_to_shoulder,es_bins);
    badbins = find(pdf_es<thresh);
    remove_es = ismember(ind,badbins) | elbow_to_shoulder > es_bins(end);
    
    [~,ind] = histc(wrist_to_elbow,we_bins);
    badbins = find(pdf_we<thresh);
    remove_we = ismember(ind,badbins) | wrist_to_elbow > we_bins(end);
    
    removeid = remove_sh | remove_es | remove_we;
    
    %left body side
    shoulder_to_head = sqrt(sum((bsxfun(@minus,detections.(field_name).locs(:,[7],:),detections.(field_name).locs(:,1,:))).^2));
    shoulder_to_head = shoulder_to_head(:)/shoulder_to_shoulder;
    
    elbow_to_shoulder = sqrt(sum(  (detections.(field_name).locs(:,[7],:)-detections.(field_name).locs(:,[5],:)).^2));
    elbow_to_shoulder = elbow_to_shoulder(:)/shoulder_to_shoulder;
    
    wrist_to_elbow = sqrt(sum(  (detections.(field_name).locs(:,[3],:)-detections.(field_name).locs(:,[5],:)).^2));
    wrist_to_elbow = wrist_to_elbow(:)/shoulder_to_shoulder;
    
    [~,ind] = histc(shoulder_to_head,sh_bins);
    badbins = find(pdf_sh<thresh);
    remove_sh = ismember(ind,badbins) | shoulder_to_head > sh_bins(end);
    
    [~,ind] = histc(elbow_to_shoulder,es_bins);
    badbins = find(pdf_es<thresh);
    remove_es = ismember(ind,badbins) | elbow_to_shoulder > es_bins(end);
    
    [~,ind] = histc(wrist_to_elbow,we_bins);
    badbins = find(pdf_we<thresh);
    remove_we = ismember(ind,badbins) | wrist_to_elbow > we_bins(end);
    
    removeid = removeid | remove_sh | remove_es | remove_we;
    
    detections.(field_name).locs(:,:,removeid) = [];
    detections.(field_name).frameids(removeid) = [];
    if isfield(detections.(field_name),'conf')
        detections.(field_name).conf(removeid,:) = [];
    end
    
    
    
    
    
    
    
    
    
    
    
    
    
    
 
    
   