%function to set job completion tag
function setjobcompletion(joblistfilename,jobid)

    jobfilename = sprintf('%s%04d.mat',joblistfilename,jobid);
    iscomplete = true;
    save(jobfilename,'iscomplete');
    