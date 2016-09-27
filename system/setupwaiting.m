%setup the file to perform job waiting
function filename = setupwaiting(filename,folder,jobid,maxjobs,tag)

    foldername = sprintf('%s%s/',folder.cache,tag);
    if ~exist(foldername,'dir'); mkdir(foldername); end
    filename.joblist = sprintf('%sjoblist_%s.mat',foldername,tag);
