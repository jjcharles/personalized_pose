%function to read in flow file and compress
function [flow_small, minmax] = compress_flow_minmax(filename)

    flow = flow.readFlowFile(filename);
    minmax = [max(max(flow(:,:,1))), min(min(flow(:,:,1)));... % channel 1
                max(max(flow(:,:,2))), min(min(flow(:,:,2)))]; % channel 2
    flow_small = cat(3, uint8(255*(flow(:,:,1)-minmax(1,2))/(minmax(1,1)-minmax(1,2))),...
                        uint8(255*(flow(:,:,2)-minmax(2,2))/(minmax(2,1)-minmax(2,2))));

    
    