%function to visualise video and joint locations
function show_locs(videofilename,imscale,frameids,locs,waittime)

    if ~exist('waittime','var'); waittime = 0; end
    
    videofolder = './videos/annotation/';
    if ~exist(videofolder,'dir'); mkdir(videofolder); end
        
        
    vidobj = VideoReader(videofilename);
    h_fig = figure;
    img = imresize(read(vidobj,frameids(1)),imscale);
    h_img = imagesc(img); axis image; hold on;
    h_title = title(sprintf('Showing frame %d of %d',1,numel(frameids)));
    set(h_title,'Fontsize',20)
    set(h_fig,'position',[1          31        1920        1094]);
    
    numlocs = size(locs,2);
    clrs = lines(numlocs);
    clrs(1,:,:) = [1 1 1];
    for n = 1:numlocs
        h_plot{n} = plot(locs(1,n,1),locs(2,n,1),'ko','markerfacecolor',clrs(n,:),'markersize',12);
    end
    
    for i = 1:numel(frameids)
        filename = sprintf('%sframe_%06d.png',videofolder,i);
        img = imresize(read(vidobj,frameids(i)),imscale);
        set(h_img,'cdata',img);
        for n = 1:numlocs
            set(h_plot{n},'xdata',locs(1,n,i),'ydata',locs(2,n,i));
        end
        set(h_title,'string',sprintf('Showing frame %d of %d',i,numel(frameids)));
%         frame = getframe(h_fig);
%         frame = imcrop(frame.cdata,1000*[0.2525    0.0735    1.4840    0.8720]);
%         
%         imwrite(frame,filename);
        drawnow
        if waittime < 0
            pause
        else
            pause(waittime)
        end
    end