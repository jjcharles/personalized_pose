%compile mex functions
fprintf('Compiling mexDenseSift\n')
%setup mexDenseSift
fulltext = fileread('./methods/mexDenseSIFT/projectTemplate.h');
if ~ispc
    fulltext = strrep(fulltext,'$$DEFINITION$$','#define _LINUX_MAC'); 
else
    fulltext = strrep(fulltext,'$$DEFINITION$$',''); 
end
fid = fopen('./methods/mexDenseSIFT/project.h','w');
fprintf(fid,'%s',fulltext);
fclose(fid);

mex ./methods/mexDenseSIFT/mexDenseSIFT.cpp ./methods/mexDenseSIFT/Matrix.cpp ./methods/mexDenseSIFT/Vector.cpp -outdir ./methods/mexDenseSIFT/
fprintf('Compiling histtree\n')
mex ./mex/histtree.cxx -outdir ./mex/
fprintf('Compiling hogfeat\n')
mex ./mex/hogfeat.cc -outdir ./mex/
fprintf('Compiling rgbhistogram\n')
mex ./mex/mre_rgbhistogram.cxx -outdir ./mex/
fprintf('Compiling rgblookup\n')
mex ./mex/mre_rgblookup.cxx -outdir ./mex/
fprintf('Compiling mxclassify\n')
mex ./mex/mxclassify.cpp -outdir ./mex/
fprintf('Compiling mxclassify_fast\n')
mex ./mex/mxclassify_fast.cpp -outdir ./mex/

fprintf('Compiling liblinearSVM\n')
%setup rootfolder for compiling liblinear
fulltext = fileread('./methods/liblinear/matlab/Makefile_template');
rootfolder = matlabroot;
rootfolder(rootfolder =='\') = '/';
fulltext = strrep(fulltext,'$$MATLABROOT$$',rootfolder); 
fid = fopen('./methods/liblinear/matlab/Makefile','w');
fprintf(fid,'%s',fulltext);
fclose(fid);

cd ./methods/liblinear/matlab/
if ispc
    make
else
    !make
end
cd ../../../

fprintf('Complete!\n')
