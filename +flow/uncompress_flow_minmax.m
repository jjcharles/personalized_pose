%function to read in flow file and uncompress
function flow_large = uncompress_flow_minmax(flow,minmax)
    
    xflow = bsxfun(@times,double(flow(:,:,1,:))/255,permute(minmax(1,1,:)-minmax(1,2,:),[1 2 4 3])) + minmax(1,2);
    yflow = bsxfun(@times,double(flow(:,:,2,:))/255,permute(minmax(2,1,:)-minmax(2,2,:),[1 2 4 3])) + minmax(2,2);
    flow_large = cat(3,xflow,yflow);
    