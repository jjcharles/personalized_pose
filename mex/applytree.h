

#include <stdlib.h>
int ApplyTree(int nodeid, double* node, double* data, int m, int n,int index)
{
    //double     offset1[2];
    //double     offset2[2];
	//double     thresh;
    //double     channel;
    int        idx_off1;
    int        idx_off2;
    double     feature;
    int nodeidr = nodeid;
    
    
    //offset1[0] = node[nodeidr + 4];//node->offset1[0];
    //offset1[1] = node[nodeidr + 5];//node->offset1[1];
    //offset2[0] = node[nodeidr + 6];//node->offset2[0];
    //offset2[1] = node[nodeidr + 7];//node->offset2[1];
    //thresh  = node[nodeidr + 9];//node->thresh;
    //channel = node[nodeidr + 10];//node->channel;
    
    
    idx_off1 = index + (m*n)*(node[nodeidr + 10]-1) + node[nodeidr + 4]*m + node[nodeidr + 5];
    idx_off2 = index + (m*n)*(node[nodeidr + 10]-1) + node[nodeidr + 6]*m + node[nodeidr + 7];
    
    if (node[nodeidr+2]==0) {
        switch ((int)node[nodeidr+8]) {
            case 1:
                feature = data[idx_off1];
                break;
            case 2:
                feature = data[idx_off1] - data[idx_off2];
                break;
            case 3:
                if (data[idx_off1]<= data[idx_off2])
                    feature = data[idx_off2] - data[idx_off1];
                else
                    feature = data[idx_off1] - data[idx_off2];
                break;
            case 4:
                    feature = data[idx_off1] + data[idx_off2];
                break;
        }

        if (feature <= node[nodeidr + 9])
            nodeidr = ApplyTree((int)node[nodeidr],node,data, m, n, index);
        else
            nodeidr = ApplyTree((int)node[nodeidr+1],node,data, m, n, index);
    } 
    return nodeidr;
}