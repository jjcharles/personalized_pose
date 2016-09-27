%function to visualise video and joint locations
function show_skeleton(videofilename,imscale,frameids,locs,secs)

    vidobj = VideoReader(videofilename);
    figure
    img = imresize(read(vidobj,frameids(1)),imscale);
    h_img = imagesc(img); axis image; hold on
    h_plot = plot_skeleton(zeros(2,size(locs,2)),inf(2,size(locs,2)),1,[],[]);
    h_title = title(sprintf('Showing frame %d of %d',1,numel(frameids)));

    for i = 1:numel(frameids)
        img = imresize(read(vidobj,frameids(i)),imscale);
        set(h_img,'cdata',img);
        plot_skeleton(locs(:,:,i),inf(2,size(locs,2)),1,[],h_plot);
        set(h_title,'string',sprintf('Showing frame %d of %d',i,numel(frameids)));
        drawnow
        if secs < 0
            pause
        else
            pause(secs)
        end
    end