%function to get patch from frame
function [patch,bbox] = getpatch(pos,patchwidth,frame)

    %if pos out of bounds then bring back to min or max
    [M,N,~] = size(frame);
    if pos(1)>N; pos(1)=N; end; if pos(1)<1; pos(1)=1; end;
    if pos(2)>M; pos(2)=M; end; if pos(2)<1; pos(2)=1; end;

    framepadded = padarray(frame,[patchwidth,patchwidth],0,'both');
    pos = pos + patchwidth;
    bbox = round([pos(1)-patchwidth/2, pos(2) - patchwidth/2,patchwidth,patchwidth]);
    datax = bbox(1):(bbox(1) + bbox(3)-1);
    datay = bbox(2):(bbox(2) + bbox(4)-1);
    patch = framepadded(datay,datax,:);