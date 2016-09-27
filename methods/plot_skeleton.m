%PLOT_SKELETON - plots skelton of signer on figure
%   handle = plot_skeleton(j,opts,handle) j is a 2x7 vector of joints, handle is a struct
%   handle.axis
%   handle.ula - upper left arm
%   handle.ura - 
%   handle.lla - lower left arm
%   handle.lra
%   handle.joints(7)
%   
%   opts.clr = jet(7) = joints
%   opts.clr(8,:) = upper arm color
%   opts.clr(9,:) = lower arm color
%   opts.linewidth = 5;
%   opts.jointsize = 10;
%   if no axis handle specified then first plot creates the handles and
%   returns them
%   v2 - accepts a confidence and threshold value as input and only
%   displays limbs if above a threshold
function handle = plot_skeleton(j,conf,thresh,opts,handle)
    
    %hack to get plot command working with any number of joints
    n = 11-size(j,2);
    j = cat(2,j,repmat([-10;-10],[1 n]));
    if isempty(opts)
        opts.clr = lines(11); %sets colour of joints
        opts.clr(8,:) = [1 0 0];
        opts.clr(9,:) = [0 1 0];
        opts.linewidth = 5;
        opts.jointsize = 10;
    end
    
    if ~isfield(opts,'jointlinewidth')
        opts.jointlinewidth = 1;
    end
    
    if ~isfield(opts,'jointlinecolor')
        opts.jointlinecolor = zeros(11,3);
    end
    
    if isscalar(opts.jointsize)
        opts.jointsize = opts.jointsize*ones(11,1);
    end
    
    if isscalar(opts.jointlinewidth)
        opts.jointlinewidth = opts.jointlinewidth*ones(11,1);
    end
    
    if nargin < 3 || isempty(handle)%initialise plot handles
        handle.axis = gca; %current axis
        %draw skelton
        handle.ula = plot(handle.axis,j(1,[5,7]),j(2,[5,7]),'y-','linewidth',opts.linewidth ,'color',opts.clr(8,:));   
        hold on
        handle.ura = plot(handle.axis,j(1,[4,6]),j(2,[4,6]),'y-','linewidth',opts.linewidth ,'color',opts.clr(8,:));
        handle.lla = plot(handle.axis,j(1,[3,5]),j(2,[3,5]),'r-','linewidth',opts.linewidth ,'color',opts.clr(9,:));
        handle.lra = plot(handle.axis,j(1,[2,4]),j(2,[2,4]),'r-','linewidth',opts.linewidth ,'color',opts.clr(9,:));
        %draw joints
        for c = 1:11
            if j(1,c)<0; continue; end
            if conf(c) > thresh
                handle.joints(c) =  plot(handle.axis,j(1,c),j(2,c),'bo', ...
                    'markerfacecolor',opts.clr(c,:), 'markersize',opts.jointsize(c),'linewidth',opts.jointlinewidth(c),'color',opts.jointlinecolor(c,:));
            end
        end
    else
        %draw skelton
        if conf(3) > thresh && conf(5) > thresh && ~any(j(1,[3,5])==-999)
            set(handle.lla,'xdata',j(1,[3,5]),'ydata',j(2,[3,5]));
        else
            set(handle.lla,'xdata',[-999,-999],'ydata',[-999,-999]);
        end
        
        
        if conf(2) > thresh && conf(4) > thresh && ~any(j(1,[2,4])==-999)
            set(handle.lra,'xdata',j(1,[2,4]),'ydata',j(2,[2,4]));
        else
            set(handle.lra,'xdata',[-999,-999],'ydata',[-999,-999]);
        end
        
        if conf(5) > thresh && conf(7) > thresh && ~any(j(1,[5,7])==-999)      
            set(handle.ula,'xdata',j(1,[5,7]),'ydata',j(2,[5,7]));
        else
            set(handle.ula,'xdata',[-999,-999],'ydata',[-999,-999]);
        end
        
        if conf(4) > thresh && conf(6) > thresh && ~any(j(1,[4,6])==-999)
            set(handle.ura,'xdata',j(1,[4,6]),'ydata',j(2,[4,6]));
        else
            set(handle.ura,'xdata',[-999,-999],'ydata',[-999,-999]);
        end
        %draw joints
        for c = 1:11
             if j(1,c)==-10; continue; end
             if conf(c) > thresh
               set(handle.joints(c),'xdata',j(1,c),'ydata',j(2,c));
             else
                 set(handle.joints(c),'xdata',-999,'ydata',-999); 
             end
        end
    end



