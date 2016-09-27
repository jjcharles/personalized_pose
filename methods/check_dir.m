%function to check and correct directory name
function [directory_out,isthere] = check_dir(directory_in,iscreate)
   
    if ~exist('iscreate','var')
        iscreate = false;
    end
    
    directory_out = directory_in;
    directory_out(directory_out=='\') = '/'; %change to unix style
    if directory_out(end) ~= '/'
        directory_out(end+1) = '/';
    end
    
    if ~exist(directory_out,'dir')
        isthere = false;
        if iscreate
            mkdir(directory_out);
        end
    else
        isthere = true;
    end