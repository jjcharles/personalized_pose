%hangs for all jobs to finish
function waitforremainingjobs(filename,maxjobs)

    joblist = dir(sprintf('%s*',filename.joblist));
    fprintf('waiting for %s\n',filename.joblist(1:end-4));
    while numel(joblist)<(maxjobs-1)
        pause(10)
        %get list of all running jobs
        joblist = dir(sprintf('%s*',filename.joblist));
    end
    
   
        