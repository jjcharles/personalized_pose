%% ------ folder paths -------
folder.main = 'F:/demo_data/';
folder.video = [folder.main 'videos/'];
folder.flow = [folder.main 'optical_flow/'];
folder.experiment = check_dir('./experiments/',true);
folder.initialisation = [folder.main 'initialisation/'];

%% ------ forest options -------
opts.model.rotations = [10 -30  30 10]; % rotation augmentations
opts.model.modelscale = 0.5; %run model at half image resoluiton for training purposes (NOTE features are still learnt at full resolution, but scaled during run time)
opts.model.forest.max_conf = 2; %maximum amount of confidence for a label at a node for it to be then turned into a leaf node (not used here)
opts.model.windows.widths = [151 151 151 151 151 151 151 151 151];
opts.model.small_windowwidth = 15;
opts.model.windows.depths = [15 25 32 64 96 128 128 142 200];
opts.model.windowwidth        = max(opts.model.windows.widths);
opts.model.matching.patchwidth = 15*4-1;
opts.model.matching.hogcellsize = 4;
opts.model.flow.patchwidth = 15*3-1;
opts.model.padding = ceil(opts.model.windowwidth/2) + 1;
   
opts.model.numchannels        = 3;         %number of channels in image representation
opts.model.numfunctypes       = 4;         %number of test functions to use - defined by func_pointer.m
opts.model.numwindows         = 7*49+100;%300;       %number of windows to sample per image
opts.model.numsampletests     = 20;       %number of random tests to try when searching for a node split function
opts.model.forest.pertreepercent = 0.5;     %percentage of gt images sampled per tree
opts.model.numclasses         = 8;         %number of different labels + background (background label is assumed to be max label throughout, i.e. if there are 7 object labels then background label is 8.
opts.model.min_pernode        = 100;        %minimum number of samples to allow at a node during training
opts.model.patchwidth         = 4;         %radius of object patch
opts.model.forest.numtrees    = 4;         %number of trees to use in forest (use 16 for very good performance)
opts.model.forest.maxdepth    = 92;        %maximum depth to grow each tree
opts.model.forest.balance_term = 0;        %specifies the amount of balancing conducted on tree during training
opts.model.pixel_quantisation_size = [256, 256, 256];  %the number of different values a pixel can take
opts.model.tests_per_channel   = {[1 2 3 4], [1 2 3 4], [1 2 3 4],[1 2 3 4],[1 2 3 4], [1 2 3 4],[1 2 3 4], [1 2 3 4], [1 2 3 4], [1 2 3 4], [1 2 3 4], [1 2 3 4]}; %defines the types of tests that can be performed on each channel 
opts.model.channel_sample_ratio = [1 1 1 1 1 1 1 1 1 1 1 1]; % defines the ratio of the number of samples taken for each channel. eg. if for channel 1 we take 100 samples then for channel 4 we take 400 samples.