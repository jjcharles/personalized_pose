%function to train and tune an svm classifier
function [svmmodel, best_thresh] = train_svm_classifier(labels,data,required_sensitivity)
    labels = labels(:);
    %first get c value right
    trialc = 100./10.^[1:15]; 
    c_score = zeros(1,numel(trialc));
    for cc = 1:numel(trialc)
         %split data into training and validation 60% train 40% validate
        posid = find(labels);
        negid = find(~labels);
        Rpos = randperm(numel(posid));
        Rneg = randperm(numel(negid));
        cutoffpos = floor(numel(posid)*0.6);
        cutoffneg = floor(numel(negid)*0.6);
        train_id = cat(1, posid(Rpos(1:cutoffpos)), negid(Rneg(1:cutoffneg)));
        val_id = cat(1, posid(Rpos((cutoffpos+1):end)), negid(Rneg((cutoffneg+1):end)));
        svmmodel = train_linsvm(labels(train_id), sparse(double(data(train_id,:))), sprintf('-c %d -s 1 -w1 %d -q',trialc(cc),0.5*sum(~labels(train_id))/sum(labels(train_id))));
        [~, ~, response] = predict_linsvm(labels(val_id),sparse(double(data(val_id,:))), svmmodel,'-q');
        response_label = response > 0;
        TP = sum(response_label & labels(val_id));
        TN = sum(~response_label & ~labels(val_id));
        FP = sum(response_label & ~labels(val_id));
        FN = sum(~response_label & labels(val_id));
        sensitivity = TP/(TP+FN);
        specificity = TN/(TN+FP);
        c_score(cc) = sum(sensitivity^2 + specificity^2);
    end
    [~,bestcid] = max(c_score);
    c = trialc(bestcid);

    numthresh = 1000; %number of thresholds to try

    %repeat this 10 times for different train and test sets then
    %take the average threshold and retrain model on all data
    trial_thresholds = zeros(1,50);


    for trial = 1:50
        %split data into training and validation 60% train 40% validate
        posid = find(labels);
        negid = find(~labels);
        Rpos = randperm(numel(posid));
        Rneg = randperm(numel(negid));
        cutoffpos = floor(numel(posid)*0.6);
        cutoffneg = floor(numel(negid)*0.6);
        train_id = cat(1, posid(Rpos(1:cutoffpos)), negid(Rneg(1:cutoffneg)));
        val_id = cat(1, posid(Rpos((cutoffpos+1):end)), negid(Rneg((cutoffneg+1):end)));
        svmmodel = train_linsvm(labels(train_id), sparse(double(data(train_id,:))), sprintf('-c %d -s 1 -w1 %d -q',c,0.5*sum(~labels(train_id))/sum(labels(train_id))));

        %validate the threshold so as to achieve high accuracy for
        %positives
        [~, ~, response] = predict_linsvm(labels(val_id),sparse(double(data(val_id,:))), svmmodel,'-q');
        threshvals = linspace(min(response),max(response),numthresh);
        sensitivity = zeros(1,numthresh);
        specificity = zeros(1,numthresh);

        for t = 1:numthresh
            response_label = response > threshvals(t);
            TP = sum(response_label & labels(val_id));
            TN = sum(~response_label & ~labels(val_id));
            FP = sum(response_label & ~labels(val_id));
            FN = sum(~response_label & labels(val_id));
            sensitivity(t) = TP/(TP+FN);
            specificity(t) = TN/(TN+FP);
        end

        best_thresh_id = find(specificity>required_sensitivity,1,'first');
        best_thresh = threshvals(best_thresh_id);
        trial_thresholds(trial) = best_thresh;
    end
    best_thresh = mean(trial_thresholds);
    %retrain svm on all data
    svmmodel = train_linsvm(labels, sparse(double(data)), sprintf('-c %d -s 1 -w1 %d -q',c,0.5*sum(~labels)/sum(labels)));

    %threshold and retrain on remaining positives
    [~, ~, response] = predict_linsvm(labels,sparse(double(data)), svmmodel,'-q');
    svmmodel.thresh = best_thresh;

    response_label = response > best_thresh;%threshvals(best_thresh_id);
     TP = sum(response_label & labels);
    TN = sum(~response_label & ~labels);
    FP = sum(response_label & ~labels);
    FN = sum(~response_label & labels);
    sensitivity = TP/(TP+FN)
    specificity = TN/(TN+FP)