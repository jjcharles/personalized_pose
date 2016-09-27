%function to perform exemplar svm clustering
function [labels, dists] = exemplarsvm_cluster(centroids,data,labels)
%thresh is a value between 0 and 1 which will discard data items if they
%are not close to a centroid, higher the thresh, the tighter the control
%data must be scaled between 0 and 1
    data = sparse(double(data));
    sp_centroids = sparse(double(centroids));
    %for each centroid train a linear svm
    numcentroids = size(centroids,2);
    for c = 1:numcentroids
        if sum(labels==c)==0; continue; end
        fprintf('exemplar %d of %d training\n',c,numcentroids)
        training_labels = zeros(numcentroids,1);
        training_labels(c) = 1;
        training_labels = cat(1,training_labels,(labels==c)');
        model(c).svmmodel = train_linsvm(training_labels, cat(2,sp_centroids,data), sprintf('-c 0.001 -s 1 -w1 %d -q',sum(~training_labels)/sum(training_labels)),'col');
        
        %calibrate
        [~, ~, decision_values] = predict_linsvm(ones(sum(labels~=c),1), data(:,labels~=c), model(c).svmmodel,'-q','col');
        numbins = 1000;
        bins = linspace(min(decision_values),max(decision_values),numbins);
        decision_hist = histc(decision_values,bins);
        decision_cdf = cumsum(decision_hist)/sum(decision_hist);
        model(c).calibcurve_y = decision_cdf;
        model(c).calibcurve_x = bins;
    end
    
    %for each centroid calculate exemplar svm distance, i.e. classify
    numitems = size(data,2);
    dists = inf(numcentroids,numitems);
    for c = 1:numcentroids
        if sum(labels==c)==0; continue; end
        fprintf('calculating distance %d of %d training\n',c,numcentroids)
        [~, ~, decision_values] = predict_linsvm(ones(numitems,1), data, model(c).svmmodel,'-q','col');
        calibdists = bsxfun(@minus,model(c).calibcurve_x,decision_values);
        [~,calibid] = min(abs(calibdists),[],2);
        dists(c,:) = model(c).calibcurve_y(calibid);
    end
    
    [dists,labels] = min(dists);
