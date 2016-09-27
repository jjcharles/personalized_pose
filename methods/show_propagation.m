function show_propagation( detections1,detections2,fieldname,labels,legend_labels)
%SHOW_PROPAGATION illustrate the difference between two sets of joint
%detections

    figure;
    
    numDetections1 = sum(detections1.(fieldname).locs(1,:,:)~=-999,3);
    numDetections2 = sum(detections2.(fieldname).locs(1,:,:)~=-999,3);
    
    bar(numDetections2)
    hold on
    bar(numDetections1,'g')
    hold off
    grid on
    xlabel('Body parts')
    ylabel('Number of frames annotated')
    set(gca,'xticklabel',labels)
    legend(legend_labels(end:-1:1));
    title('Propagation of annotation')
    
end

