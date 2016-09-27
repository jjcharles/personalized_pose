#include <mex.h>

typedef unsigned char uint8_t;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	if (nrhs != 2)
		mexErrMsgTxt("two input arguments expected");
	if (nlhs != 1)
		mexErrMsgTxt("one output argument expected");

	if (!mxIsUint8(prhs[0]) ||
		mxGetNumberOfDimensions(prhs[0]) != 3 ||
		mxGetDimensions(prhs[0])[2] != 3)
		mexErrMsgTxt("argument 1 must be uint8 h x w x 3");

	if (!mxIsDouble(prhs[1]) ||
		mxIsComplex(prhs[1]) ||
		mxGetNumberOfDimensions(prhs[1]) != 3 ||
		mxGetDimensions(prhs[1])[1] != mxGetDimensions(prhs[1])[0] ||
		mxGetDimensions(prhs[1])[2] != mxGetDimensions(prhs[1])[1])
		mexErrMsgTxt("argument 2 must be real double b x b x b");

	int bins = mxGetDimensions(prhs[1])[0];
	int shiftr = 8;
	for (int sbins = 1; sbins <= 256; sbins <<= 1, shiftr--)
	{
		if (sbins == bins)
			break;
	}
	if (shiftr < 0)
		mexErrMsgTxt("bins must be power of 2 in 1..256");

	int h = mxGetDimensions(prhs[0])[0], w = mxGetDimensions(prhs[0])[1], n = h * w;

	plhs[0] = mxCreateDoubleMatrix(h, w, mxREAL);

	double *out = mxGetPr(plhs[0]);
	const uint8_t *R = (const uint8_t *) mxGetData(prhs[0]), *G = R + n, *B = G + n;
	const double *LUT = mxGetPr(prhs[1]);
	const int shiftlg = 8 - shiftr, shiftlb = shiftlg << 1;

	for (int i = 0; i < n; i++)
		*(out++) = LUT[((*R++) >> shiftr) + (((*G++) >> shiftr) << shiftlg) + (((*B++) >> shiftr) << shiftlb)];
}
