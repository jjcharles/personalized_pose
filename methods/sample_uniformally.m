%function to sample uniformally from a set of points from R^n using a
%maximal coverage algorithm with window width as a parameter. I.e. it
%covers the input set with the minimum number of cirular windows with
%diameter given by 'window_width'. It then samples uniformally with
%replacement from each covered region.
function sampleid = sample_uniformally(data,window_width,num_samples)

    visualise = false;

    [centroids, labels] = getbestclusters(data,window_width);
    num_centroids = size(centroids,2);
    if num_samples < num_centroids
        num_samples = num_centroids;
        fprintf('WARNING number of samples too low, increasing to minimum %d\n',num_samples)
    end
    
    num_per_centroid = round(num_samples/num_centroids);
    sampleid = zeros(1,num_per_centroid*num_centroids);
    
    count = 1;
    for l = 1:num_centroids
        within_group = find(labels==l);
        
        %sample from within group
        if numel(within_group) < num_per_centroid
            R = 1:numel(within_group);
            R = cat(2,R,floor(rand(1,num_per_centroid-numel(within_group)) * (numel(within_group)-1)) + 1);
        else
            R = randperm(numel(within_group));
            R = R(1:num_per_centroid);
        end
        sampleid(count:(count + num_per_centroid-1)) = within_group(R(1:num_per_centroid));
        count = count + num_per_centroid;
    end
    
    if visualise
    
        figure
        clrs = lines(size(centroids,2)); 
        for l = unique(labels); 
            plot(data(1,labels==l),data(2,labels==l),'b.','color',clrs(l,:)); 
            text(centroids(1,l),centroids(2,l),sprintf('%d',l))
            hold on; 
        end
        
        title('maximal coverage groups')
        
        
        figure
        plot(data(1,:),data(2,:),'r.'); 
        title('input points')
        
        figure
        plot(data(1,sampleid),data(2,sampleid),'r.'); 
        title('uniformally sampled points')
        
        figure
        ridx = randperm(size(data,2));
        plot(data(1,ridx(1:num_samples)),data(2,ridx(1:num_samples)),'r.');
        title('example of sampling without maximal coverage');
    end
    sampleid = sort(sampleid);


