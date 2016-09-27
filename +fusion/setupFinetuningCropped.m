function [filename,folder] =  setupFinetuningCropped(cnnopts,exp_name,videoname,videoFilename,trainFrameids,trainLocs,testFrameids,testLocs,imscale,bbWidth,bbHeight)
%SETUPFINETUNINGCROPPED Setup model for fine tuning on input data
%CROPPED VERSION - trains by cropping out a 256 by 256 bounding box around the person
    %setup data
    [ train_data_file, test_data_file] = fusion.setupTrainingDataCropped(cnnopts,exp_name,videoname,videoFilename,trainFrameids,trainLocs,testFrameids,testLocs,imscale,bbWidth,bbHeight);

    
    %setup training definition file
    folder.model = check_dir(sprintf('%s%s/heatmap_finetuned/%s',cnnopts.finetune.main_save_folder,exp_name,videoname),true);
    filename.def= sprintf('%strain_val.prototxt',folder.model);
    str = fileread(cnnopts.finetune.base_def_file);
    outstr = sprintf(str,train_data_file,test_data_file);
    fid = fopen(filename.def,'w');
    fprintf(fid,'%s',outstr);
    fclose(fid);
    
    %setup solver definition file
    folder.model_snapshots = check_dir(sprintf('%ssnapshots',folder.model),'true');
    filename.solver= sprintf('%ssolver.prototxt',folder.model);
    str = fileread(cnnopts.finetune.base_solver_file);
    outstr = sprintf(str,filename.def,folder.model_snapshots);
    fid = fopen(filename.solver,'w');
    fprintf(fid,'%s',outstr);
    fclose(fid);

    %setup training bash script
    runstr = sprintf('%sbuild/tools/caffe train -weights %s -gpu 0 -solver %s  2>&1 | tee -a %strain_log.txt ',cnnopts.finetune.cafferoot,cnnopts.finetune.model_filename,filename.solver,folder.model);
    filename.bash= sprintf('%strain.sh',folder.model);
    str = fileread(cnnopts.finetune.base_train_script);
    outstr = sprintf(str,runstr);
    fid = fopen(filename.bash,'w');
    fprintf(fid,'%s',outstr);
    fclose(fid);
    
    %set bash script to executable
    system(sprintf('chmod u=rwx %s',filename.bash));
    
    fprintf('Execute %s to fine tune on %s\n',filename.bash,videoname);
end

