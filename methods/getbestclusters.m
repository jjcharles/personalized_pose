%function to pick best covering of a set given a support window 
function [centroids, clusterids]  = getbestclusters(data,windowsize)

max_clusters = min(50,size(data,2));
centroids = [];
clusterids = [];
visualise = false;

for k = 1:max_clusters
    isgood = true;
    [c,id] = vl_kmeans(double(data),k,'Initialization', 'plusplus');
    
    %if any cluster is out of range of window size then increase number of
    %clusters
    for j = 1:k
        dists = sqrt(sum((bsxfun(@minus,data(:,id==j),c(:,j))).^2));
        if any(dists>(mean(windowsize/2)))
            isgood = false;
            break
        end
    end
    
    if isgood
        centroids = c;
        clusterids = id;
        break;
    end
end
centroids = c;
clusterids = id;
if visualise
    figure
    clrs = lines(size(centroids,2)); 
    for l = unique(clusterids); 
        plot(data(1,clusterids==l),data(2,clusterids==l),'b.','color',clrs(l,:)); 
        text(centroids(1,l),centroids(2,l),sprintf('%d',l))
        hold on; 
    end
end