% Demonstration code to propagate initial pose estimates throughout a
% video using the methods described in the below paper. If you use this code please
% cite:
%
% [1] @InProceedings{Charles16,
%   author       = "Charles, J. and Pfister, T. and Magee, D. and Hogg, D. and Zisserman, A.",
%   title        = "Personalizing Human Video Pose Estimation",
%   booktitle    = "IEEE Conference on Computer Vision and Pattern Recognition",
%   year         = "2016",
% }
%
%   Usage instructions:
%   1. First compile mex functions by running compile.m
%   2. Install VLfeat
%   3. Download demo video and data according to README
%   4. Set the paths in the options file at ./options/part_detector_options_youtube.m
%   appropriately, as explained in the README
%
%   Approximately 1.3GB of memory is required to run the code on the
%   provided demo video. The code operates at 12 seconds per frame on
%   average on a 2.2GHz i7. Two demo videos are provided video one is 1800 frames in length
%   and the other 301 frames. Average shoulder width over frames is around 100 pixels.
%
%   The longer video is called: E7ULR-yfNnk_cut
%   The shorter video is called: E7ULR-yfNnk_vshort
%
%   This work is licensed under the Creative Commons Attribution 4.0 International License. 
%   To view a copy of this license, visit http://creativecommons.org/licenses/by/4.0/ or 
%   send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
%
%   Code provided by James Charles (jjcvision@gmail.com)

%setup paths
set_paths

%set to true if you also want to finetune a ConvNet after
%propagation
isFineTune = false;

%set option to run over multiple cpus, note: this will increase memory
%requirments
num_cpus = 1;

%settings to operate on demo video
videoname = 'E7ULR-yfNnk_vshort'; %to test on a longer video use: videoname = 'E7ULR-yfNnk_cut'
dataset = 'youtube';

%load options file and paths
[opts,folder] = load_system_options(dataset,videoname);
[filename,folder] = setup_filenames(folder, videoname, dataset);

%set filename to initial pose estimates. These pose estimates were
%produced as in [1]. See README for constructing this file.
initial_det_file = sprintf('%s%s.mat',folder.initialisation,videoname);

%visualise the initial pose estimates
load(initial_det_file);
show_skeleton(filename.video,1,detections.manual.frameids,detections.manual.locs,0);

%propagate the initial pose estimates
fprintf('Press any key to continue with propagating poses...\n');
pause

if num_cpus <= 1
    detections = propagate(videoname,dataset,initial_det_file,1,1,1);
else
    parpool(num_cpus)
    parfor j = 1:num_cpus
        detections = propagate(videoname,dataset,initial_det_file,1,j,num_cpus);
    end
end

%visualise the propagated pose estimates
show_skeleton(filename.video,1,detections.manual.frameids,detections.manual.locs,0);

%show a graph illustrating propagation effect
initdet = load(initial_det_file);
show_propagation(initdet.detections,detections,'manual',{'Head','R Wrist','L Wrist','R Elbow','L Elbow','R Shldr','L Shldr'},{'Initial','After propagation'});

%personalize/finetune the ConvNet
if isFineTune
    fprintf('Press any key to personalize/finetune the ConvNet...\n');
    pause

    %create training files (dummy testing files are generated but not used here)
    fusion.setupFinetuningCropped(opts.cnn,dataset,videoname,...
        filename.video,detections.manual.frameids,...
        detections.manual.locs,detections.manual.frameids(1),...
        detections.manual.locs(:,:,1),opts.imscale,...
        opts.cnn.finetune.dims(1),opts.cnn.finetune.dims(2));
end






