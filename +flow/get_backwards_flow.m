%function to produce flow backwards from flow going fowards using iterative fixed
%point algorithm: flowback_nplus(x) = -flowforward(x+flowback_n(x));
%initialise flowback_zero = -flowforward;
function reverse_flow = get_backwards_flow(flow)

    reverse_flow = zeros(size(flow));
    [M,N,~,total_frames] = size(flow);
    [r,c] = find(ones(M,N));
    idx = M*(c-1) + r;
    idx = cat(1,idx,idx+(M*N));
    count = 1;
    for i = total_frames:-1:1
            changediff = inf;
            diffold = inf;
            temp_flow1 = flow(:,:,:,i);
            temp_flow2 = -flow(:,:,:,i)+randn(M,N,2)*0.1;
            temp_flow3 = temp_flow1;
            while changediff > 0.01*(73080/(M*N))
                lookupidx = idx+round(temp_flow2(:));
                lookupidx(lookupidx<1) = 1;
                lookupidx(lookupidx>idx(end)) = idx(end);
                
                temp_flow2(lookupidx) = -temp_flow1(lookupidx);
                diffnew = sum(abs(temp_flow3(:)-temp_flow2(:)));
                changediff = abs(diffold-diffnew);
                diffold= diffnew;
                temp_flow3 = temp_flow2;
            end
            reverse_flow(:,:,:,count) = temp_flow2;
            count = count + 1;
    end