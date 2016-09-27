// Apply tree for a forest
#include "mex.h"
#include <stdlib.h>
#include <time.h>
#include "applytree.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    int m,n,img_index;
    const mxArray* apNumChannels = prhs[0];
    const mxArray* apBx = prhs[1];
    const mxArray* apBy = prhs[2];
    const mxArray* apBwidth = prhs[3];
    const mxArray* apBheight = prhs[4];
    const mxArray* apTree = prhs[5];
    const mxArray* apData = prhs[6];
    const mxArray* apNumclasses = prhs[7];
    
    int numclasses = mxGetScalar(apNumclasses);
    
    double* data = mxGetPr(apData);
	double* tree = mxGetPr(apTree);
    
    m = mxGetM(apData);
    n = mxGetN(apData)/mxGetScalar(apNumChannels);
    int box_width = (int)mxGetScalar(apBwidth);
    int box_height = (int)mxGetScalar(apBheight);
    int numchannels = (int)mxGetScalar(apNumChannels);
    
    //setup output array
    plhs[0] = mxCreateDoubleMatrix(box_height*box_width,numclasses,mxREAL);
    double* output = mxGetPr(plhs[0]);
    
    plhs[1] = mxCreateDoubleMatrix(box_height,box_width,mxREAL);
    double* leafid = mxGetPr(plhs[1]);
    
    int nodeid;
    
    img_index = ((int)mxGetScalar(apBx)-1)*m -2 + (int)mxGetScalar(apBy);
    for (int i = 0; i<(box_width*box_height); i++) {
        if ( ((i % box_height) == 0) && (i!=0)) {
            img_index += (m-box_height+1);
        } else {
            img_index += 1;
        }
        nodeid = ApplyTree(0,tree,data,m,n,img_index);
        
        for (int c = 0; c<numclasses; c++) {
            output[i + (int)(c*(box_height*box_width))] = tree[nodeid + 11 + c];
            leafid[i] = (double)nodeid/19+1;
        }
        
    }
}
