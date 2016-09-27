%new function to setup filenames
function [filename,folder] = setup_filenames(folder, videoname, exp_name)

switch lower(exp_name)
    case 'youtube'
        filename.video = sprintf('%s%s.mj2',folder.video,videoname);
end

if ~exist(filename.video,'file')
    filename.video = sprintf('%s%s.avi',folder.video,videoname);
end

folder.model = sprintf('%s%s/%s/',folder.experiment,exp_name,videoname);
folder.partmodel = sprintf('%s%s/%s/',folder.experiment,exp_name,videoname);

folder.cache = sprintf('%scache/',folder.model);

filename.patches = sprintf('%svideoToColorprogramme_%s_v1.mat',folder.cache,videoname);
filename.flow = sprintf('%s%s.mat',folder.flow,videoname);

filename.detections = sprintf('%sdetections_itr_01.mat',folder.model);
filename.saved_initial_detections = sprintf('%ssaved_initial_detections.mat',folder.model);

if ~exist(folder.cache,'dir'); mkdir(folder.cache); end
if ~exist(folder.model,'dir'); mkdir(folder.model); end
if ~exist(folder.partmodel,'dir'); mkdir(folder.partmodel); end