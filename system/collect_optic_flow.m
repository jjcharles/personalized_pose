%function for producing dense optic flow video using DeepFlow
function collect_optic_flow(videoname,exp_name)
 
    %setup filenames and folders
    [opts,folder] = load_system_options(exp_name,videoname);
    [filename,folder] = setup_filenames(folder, videoname, exp_name);

    %create matfile for optical flow output
    flowFilename = sprintf('%s%s.mat',folder.flow,videoname);
    flow_file = matfile(flowFilename,'Writable',true);
    
    %create folder for storing temporary flo files
    temp_folder = check_dir(sprintf('%s%s_temp',folder.flow,videoname),true);
    
    %load video
    vidobj = VideoReader(filename.video);
    numFrames = vidobj.NumberOfFrames;
    
    %initialise flow file
    if ~exist(flowFilename,'file')
        %initialise flow file
        flow_file.flow(vidobj.Height,vidobj.Width,2,numFrames) = uint8(0); 
        flow_file.minmax(2,2,numFrames) = double(0);
        flow_file.flow_count = 1;
    end

    startid = flow_file.flow_count;
    
    if flow_file.flow_count < numFrames
        for i = startid:(numFrames-1)
            frameid1 = i;
            frameid2 = i+1;

            outfilename = sprintf('%s%s_%05d.flo',temp_folder,videoname,frameid1);
            infilename1 = sprintf('%s%s_%05d.jpg',temp_folder,videoname,frameid1);
            infilename2 = sprintf('%s%s_%05d.jpg',temp_folder,videoname,frameid2);
            
            try
                imwrite(read(vidobj,frameid1),infilename1);
                imwrite(read(vidobj,frameid2),infilename2);
            catch 
                fprintf('read frame %d or %d of video %s failed, continuing..',frameid1,frameid2,videoname);
            end

            fprintf('Computing optic flow for video %s, frame %d of %d\n',videoname,frameid1,numFrames-1);

            sys_str = sprintf('%s %s %s %s -middlebury',...
                opts.deepflowstatic, ...
                infilename1, infilename2, outfilename);

            sysmsg = system(sys_str);

            %compress and store flow file
            [flowval,minmax] =  flow.compress_flow_minmax(outfilename);
            flow_file.flow(:,:,:,flow_file.flow_count) = flowval;
            flow_file.minmax(:,:,flow_file.flow_count) = minmax;
            flow_file.flow_count = flow_file.flow_count + 1;
            delete(infilename1,infilename2,outfilename);
        end
        fprintf('done\n');
        vidobj.delete;
    end

                        