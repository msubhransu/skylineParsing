#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "mex.h"

// Author: Subhransu Maji
// May 4, 2013

// Compute the 8 connected component of the graph
void computeEightConnectedGraph(mxArray* plhs[], const mxArray* prhs[]){
	
	double *image = mxGetPr(prhs[0]);
	double gamma = mxGetScalar(prhs[1]);
	const int *dims = mxGetDimensions(prhs[0]);
	int h = dims[0];
	int w = dims[1];
	
	int totalEdges = (h-2)*(w-2)*8 + 4*3 + (h-2)*2*5 + (w-2)*2*5;
	
	mxArray *src = mxCreateNumericArray(1, &totalEdges, mxINT32_CLASS, mxREAL);
	mxArray *dst = mxCreateNumericArray(1, &totalEdges, mxINT32_CLASS, mxREAL);
	mxArray *s = mxCreateNumericArray(1, &totalEdges, mxDOUBLE_CLASS, mxREAL);

	int32_t *srcI = (int32_t*)mxGetPr(src);
	int32_t *dstI = (int32_t*)mxGetPr(dst);
	double *sI = (double*)mxGetPr(s);
	
	// Eight neighbours of the image
	int offi[8] = {-1, -1, -1,  0, 0,  1, 1, 1}; 
	int offj[8] = {-1,  0,  1, -1, 1, -1, 0, 1}; 
					
	int count = 0, nbri, nbrj, srcind, dstind;
	
	// Loop over the pixels and assign weights to edges
	for(int i=0; i<h; i++){
		for(int j=0; j<w;j++){
			for(int k=0; k<8; k++){
				nbri = i + offi[k]; 
				nbrj = j + offj[k];
				if(nbri>=0 && nbri<h && nbrj>=0 && nbrj<w){ //neighbour is inside the image
					srcind = i + j*h;
					dstind = nbri + nbrj*h;
					srcI[count] = srcind+1; // correct for MATLAB's indices
					dstI[count] = dstind+1;
					sI[count] = exp(-gamma*(image[srcind] - image[dstind])*(image[srcind] - image[dstind]));
					count++;
				}
			}
		}
	}
	// Assign values to the output
	plhs[0] = src;
	plhs[1] = dst;
	plhs[2] = s;
}

// Entry code
void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){
	const char *error_msg;
	if(nrhs != 2 || nlhs != 3){
		mexPrintf("Error: incorrect number of arguments\n");
		return;
	}
	computeEightConnectedGraph(plhs, prhs);
}
