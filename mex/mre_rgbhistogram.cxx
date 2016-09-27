#include <mex.h>

typedef unsigned char uint8_t;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	if (nrhs != 2 && nrhs != 3)
		mexErrMsgTxt("two or three input arguments expected");
	if (nlhs != 1)
		mexErrMsgTxt("one output argument expected");

	if (!mxIsUint8(prhs[0]) ||
		mxGetNumberOfDimensions(prhs[0]) != 3 ||
		mxGetDimensions(prhs[0])[2] != 3)
		mexErrMsgTxt("argument 1 must be uint8 h x w x 3");

	int h = mxGetDimensions(prhs[0])[0], w = mxGetDimensions(prhs[0])[1], n = h * w;

	if (!mxIsDouble(prhs[1]) ||
		mxIsComplex(prhs[1]) ||
		mxGetNumberOfElements(prhs[1]) != 1)
		mexErrMsgTxt("argument 2 must be real double scalar");
	
	int bits = (int) mxGetScalar(prhs[1]);
	if (mxGetScalar(prhs[1]) != bits || bits < 1 || bits > 8)
		mexErrMsgTxt("argument 2 must be 1..8");

	if (nrhs == 3)
	{
		if (!(mxIsLogical(prhs[2]) || mxIsDouble(prhs[2])) ||
			mxGetNumberOfDimensions(prhs[2]) != 2 ||
			mxGetM(prhs[2]) != h ||
			mxGetN(prhs[2]) != w)
			mexErrMsgTxt("argument 3 must be logical h x w");
	}

	int hdim[3] = { 1 << bits, 1 << bits, 1 << bits };

	plhs[0] = mxCreateNumericArray(3, hdim, mxDOUBLE_CLASS, mxREAL);

	int shiftr = 8 - bits;
	int shiftlg = bits, shiftlb = bits << 1;

	const uint8_t *R = (const uint8_t *) mxGetData(prhs[0]), *G = R + n, *B = G + n;
	double *H = mxGetPr(plhs[0]);

	if (nrhs == 2)
	{
		for (int i = 0; i < n; i++)
			H[(*(R++) >> shiftr) + ((*(G++) >> shiftr) << shiftlg) + ((*(B++) >> shiftr) << shiftlb)]++;
	}
	else
	{
		if (mxIsLogical(prhs[2]))
		{
			const mxLogical *M = mxGetLogicals(prhs[2]);

			for (int i = 0; i < n; i++, R++, G++, B++)
			{
				if (*(M++))
					H[(*R >> shiftr) + ((*G >> shiftr) << shiftlg) + ((*B >> shiftr) << shiftlb)]++;
			}
		}
		else
		{
			const double *W = mxGetPr(prhs[2]);

			for (int i = 0; i < n; i++, R++, G++, B++, W++)
				H[(*R >> shiftr) + ((*G >> shiftr) << shiftlg) + ((*B >> shiftr) << shiftlb)] += *W;
		}
	}
}
