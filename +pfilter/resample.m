%function to resample particles

function particle = resample(particle,N,conf)
%N is number to resample (optional) default is same number as number of
%input particles
%always need at least number of input particles so we resample more from
%conf

    
    if nargin < 2
        N = numel(particle);
    else

    end

    x = cat(1,particle(:).x);
    y = cat(1,particle(:).y);
    weight = cat(1,particle(:).weight);
    weight = weight./(sum(weight)+eps);
    
    if sum(weight)==0
        weight = rand(numel(x),1);
        weight = weight./(sum(weight)+eps);
    end
    
    clear particle;
    for i = 1:N
        id = find(rand <= cumsum(weight),1);
        particle(i).x = x(id);  
        particle(i).y = y(id);
        particle(i).weight = weight(id);
    end
    
if isempty(particle(1).x); keyboard; end