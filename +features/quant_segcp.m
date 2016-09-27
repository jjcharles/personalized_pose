function feat = quant_segcp(opts,rgbimg,patches,seg)

    %load lookup table for quantisation
    [l_info.bin2clr, l_info.clr2bin] = colour2bin();
    
    segcp_feat = features.segcp(opts,rgbimg,patches,seg);
    %quantise frame IMPORTANT
    bin_idx = l_info.clr2bin(segcp_feat+1);
    feat = uint8(l_info.bin2clr(bin_idx));


%COLOUR2BIN - returns a lookup table to transform a colour value to a bin
%value and vice-versa
function [bin2clr, clr2bin, binedges] = colour2bin()
    opts.armmask.bins = 10;
    edges = cumsum([0, 255/opts.armmask.bins*ones(1,opts.armmask.bins)]);
    
    clr2bin = zeros(1,256);
    for clr = 0:255
        clr2bin(clr+1) = find(clr>=edges,1,'last');
    end
    clr2bin(end) = clr2bin(end)-1;
    
    bin2clr = zeros(1,opts.armmask.bins);
    for bin = 1:opts.armmask.bins
        %use the mode rather that the mean
        bin2clr(bin) = mean(find(clr2bin==bin)-1);
%         bin2clr(bin) = max(find(clr2bin==bin)-1);
    end
    binedges = edges;

