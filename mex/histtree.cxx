#include "mex.h"
//histtree(data_class, feature, class_weight, num_samples, num_classes, num_edges)
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    const mxArray* apDataClass = prhs[0];
    const mxArray* apFeature = prhs[1];
    const mxArray* apClassWeight = prhs[2];
    const mxArray* apNumSamples = prhs[3];
    const mxArray* apNumClasses = prhs[4];
    const mxArray* apNumEdges = prhs[5];
    
    unsigned char * data_class = (unsigned char *)mxGetData(apDataClass); 
    short * feature = (short *)mxGetData(apFeature);
    double* class_weight = mxGetPr(apClassWeight);
    int num_samples = mxGetScalar(apNumSamples);
    int num_classes = mxGetScalar(apNumClasses); 
    int num_edges = mxGetScalar(apNumEdges); 
    
    plhs[0] = mxCreateDoubleMatrix(num_classes,num_edges,mxREAL);
    double* output = mxGetPr(plhs[0]);
    
    //build histogram
    //HL(data_class(i),feature(i)+addon) = HL(data_class(i),feature(i)+addon)+data.class_weight(data_class(i));
    for (int i=0; i<(num_classes*num_edges); i++) {
        output[i] = 0;
    }
    
    for (int i=0; i<num_samples; i++) {
        //printf("feature: %d, data_class: %d, output: %d, class_weight: %f\n",feature[i],data_class[i],output[(feature[i]-1)*num_classes + data_class[i]-1],class_weight[data_class[i]-1]);
        output[(feature[i]-1)*num_classes + data_class[i]-1] = output[(feature[i]-1)*num_classes + data_class[i]-1] + class_weight[data_class[i]-1];
    }
}
    
