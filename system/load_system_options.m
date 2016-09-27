%function to load the correct options files
function [opts,folder] = load_system_options(exp_name,videoname)


switch lower(exp_name)
    case 'youtube'
        [opts,folder] = load_youtube_options(videoname);  
end

function [opts,folder] = load_youtube_options(videoname)
    % part_detector_options;
    part_detector_options_youtube;
    partdetector = opts;
    clear 'opts'

    %load in options file for propagation
    propagation_options_youtube;

    %set imscale to 1
    opts.imscale = 1;

    %set bbox = to size of input video
    filename.video = sprintf('%s%s.mj2',folder.video,videoname);
    if ~exist(filename.video,'file')
        filename.video = sprintf('%s%s.avi',folder.video,videoname);
    end

    
    if ~exist(filename.video,'file')
        error(sprintf('The video file: %s does not exist',filename.video))
    end
    vidobj = VideoReader(filename.video);
    opts.cnn.dims = [vidobj.Height, vidobj.Width];

    %set cnn deployment prototext
%     prototxt = fileread(opts.cnn.model_def_base);
%     prototxt = sprintf(prototxt,vidobj.Height,vidobj.Width);
%     fid = fopen(opts.cnn.model_def_file,'w');
%     fopen(fid);
%     fprintf(fid,prototxt);
%     fclose(fid);
    opts.bbox = [1 1 vidobj.Width vidobj.Height];
    opts.partdetector = partdetector;
    opts.partdetector.imscale = opts.imscale; %<----- important so all scales are the same
    opts.partdetector.bbox = opts.bbox; %<----- important so all scales are the same
    opts.partdetector.back_bbox = opts.bbox;