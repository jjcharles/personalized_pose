% This make.m is for MATLAB and OCTAVE under Windows, Mac, and Unix

% try
	Type = ver;
	% This part is for OCTAVE
	if(strcmp(Type(1).Name, 'Octave') == 1)
		mex libsvmread.c
		mex libsvmwrite.c
		mex trainsvm.c linear_model_matlab.c ../linear.cpp ../tron.cpp ../blas/*.c -output train_linsvm
		mex predictsvm.c linear_model_matlab.c ../linear.cpp ../tron.cpp ../blas/*.c -output predict_linsvm
	% This part is for MATLAB
	% Add -largeArrayDims on 64-bit machines of MATLAB
	else
		mex CFLAGS="\$CFLAGS -std=c99" -largeArrayDims libsvmread.c
		mex CFLAGS="\$CFLAGS -std=c99" -largeArrayDims libsvmwrite.c
		mex CFLAGS="\$CFLAGS -std=c99" -largeArrayDims trainsvm.c linear_model_matlab.c ../linear.cpp ../tron.cpp "../blas/*.c" -output train_linsvm
		mex CFLAGS="\$CFLAGS -std=c99" -largeArrayDims predictsvm.c linear_model_matlab.c ../linear.cpp ../tron.cpp "../blas/*.c" -output predict_linsvm
	end
% catch
% 	fprintf('If ./methods/liblinear/make.m fails, please check ./methods/liblinear/README about detailed instructions.\n');
% end
