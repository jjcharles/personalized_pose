%function to determin cluster assignment given cluster centroids and input
%vectors
function [labels dist] = label_assignment(centroids, y)

    index = flann_build_index(centroids,struct('algorithm','kdtree','tree',16));
    search_struct = struct('checks',128);
    [labels,dist] = flann_search(index,y,1,search_struct);