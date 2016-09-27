%function to train a part detector
function train_detector_tree(opts, filename, folder, maxtreedepth, jobid, maxjobs, frameids, locs)

savemaxjobs = maxjobs;
if maxjobs == 1
    jobidloop = 1:opts.partdetector.model.forest.numtrees;
    maxjobs = opts.partdetector.model.forest.numtrees;
else
    %return if jobid greater than number of trees to train
    if jobid > opts.partdetector.model.forest.numtrees;
        %set completion tag in jobfile
        setjobcompletion(filename.joblist,jobid);
        return
    end
    
    %get tree id list for training with this job
    numTreesInJob = floor(opts.partdetector.model.forest.numtrees/maxjobs);
    if opts.partdetector.model.forest.numtrees < maxjobs
        numTreesInJob = 1;
    end

    startidloop = ((jobid-1)*numTreesInJob+1);
    if jobid == maxjobs
        numTreesInJob = opts.partdetector.model.forest.numtrees - (jobid-1)*numTreesInJob; 
    end
    
    stopidloop = startidloop+numTreesInJob-1;
    jobidloop = startidloop:stopidloop;
    
    maxjobs = opts.partdetector.model.forest.numtrees;
end

save_opts = opts.partdetector;

for treeTrainID = jobidloop
    jobid = treeTrainID;
    if ~exist(folder.detector,'dir'); mkdir(folder.detector); end
    filename.tree = sprintf('%stree_%02d.mat',folder.detector,jobid);
    filename.forest = sprintf('%sforest.mat',folder.detector);
    
    if exist(filename.tree,'file')
        continue;
    end
    
    opts.partdetector = save_opts;
    
    %set random seed so as to regenerate the correct samples from previous
    %round of training
    s = RandStream('mt19937ar','Seed',jobid);
    RandStream.setGlobalStream(s);

    %if jobid is even then train a small window width tree so set the options
    if mod(jobid,2)==0
        opts.partdetector.model.windows.widths = ones(1,numel(opts.partdetector.model.windows.widths))*opts.partdetector.model.small_windowwidth;
        opts.partdetector.model.windowwidth = opts.partdetector.model.small_windowwidth;
        opts.partdetector.model.padding = ceil(opts.partdetector.model.windowwidth/2) + 1;
    end

   

    %work out memory limits (roughly)
    maxmem = 10000; %in megabytes
    maximages = floor(((maxmem-1)*1024*1024)/(numel(opts.partdetector.model.rotations)*(opts.bbox(3) + 2*opts.partdetector.model.padding)*(opts.bbox(4) + 2*opts.partdetector.model.padding)*opts.partdetector.model.numchannels));
    maximages = floor(maximages/numel(opts.partdetector.model.rotations));

    %if maximages is low i.e. less than 10000 then we need to scale the images
    minnum_images = 5000;
    isrescale = false;
    if maximages < minnum_images
        scaleval = sqrt(maximages/minnum_images);
        opts.partdetector.imscale = opts.partdetector.imscale*scaleval;
        opts.partdetector.model.windows.widths = 2*floor(round(opts.partdetector.model.windows.widths*scaleval)/2) + 1;
        opts.partdetector.model.windowwidth = max(opts.partdetector.model.windows.widths);
        opts.partdetector.model.padding = ceil(opts.partdetector.model.windowwidth/2) + 1;
        opts.partdetector.bbox = floor((opts.partdetector.bbox-1)*scaleval)+1;
        opts.partdetector.model.patchwidth = round((opts.partdetector.model.patchwidth-1)*scaleval + 1);
        invalid = locs==-999;
        locs = floor(locs*scaleval);
        locs(locs==0) = 1;

        locs(invalid) = -999;
        maximages = minnum_images;
        isrescale = true;
    end

    %scale again if window size greater than 31 pixels (this make the use of
    %larger windows possible)
    newscaleval = 31/opts.partdetector.model.windowwidth;
    if newscaleval < 1;
        opts.partdetector.imscale = opts.partdetector.imscale*newscaleval;
        opts.partdetector.model.windows.widths = 2*floor(round(opts.partdetector.model.windows.widths*newscaleval)/2) + 1;
        opts.partdetector.model.windowwidth = max(opts.partdetector.model.windows.widths);
        opts.partdetector.model.padding = ceil(opts.partdetector.model.windowwidth/2) + 1;
        opts.partdetector.bbox = floor((opts.partdetector.bbox-1)*newscaleval)+1;
        opts.partdetector.model.patchwidth = round((opts.partdetector.model.patchwidth-1)*newscaleval + 1);
        invalid = locs==-999;
        locs = floor(locs*newscaleval);
        locs(locs==0) = 1;

        locs(invalid) = -999;
        scaleval = newscaleval*scaleval;
        isrescale = true;
    end

    if numel(frameids)  >maximages %subsample
        R = randperm(numel(frameids));
        sub_frame_ids = frameids(R(1:min(numel(frameids),maximages)  ));
        sub_locs = locs(:,:,R(1:min(numel(frameids),maximages)  ));
    else
        sub_frame_ids = frameids;
        sub_locs = locs;
    end


    if jobid <= opts.partdetector.model.forest.numtrees
        if ~exist(filename.tree,'file') && ~exist(filename.forest,'file');      
            %train tree
            opts.partdetector.model.forest.maxdepth = maxtreedepth;
            tree = oforest.train_forest_cluster(opts.partdetector,filename,sub_frame_ids,sub_locs,jobid);

            %scale model if we downscaled the images
            if isrescale
                for t = 1:numel(tree)
                    if tree(t).leaf~=1
                        tree(t).test(1:4) = round(tree(t).test(1:4)/scaleval);
                    end
                end
            end

            opts = save_opts;
    %         save(filename.tree,'tree','opts','-v7.3');

            %convert to matrix representation and save
            tree = oforest.tree2mat(tree);
            save(filename.tree,'tree','opts','-v7.3');
        end
    end
end
jobid = savemaxjobs;

  %if last job then wait and compile the forest
    if jobid==maxjobs
        waitforremainingjobs(filename,maxjobs)
        model = oforest.load_forest_from_folder(folder.detector);
    end
    
%set completion tag in jobfile
setjobcompletion(filename.joblist,jobid);

    