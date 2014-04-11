/* Author : Subhransu Maji, Date : Feb 2, 2010
 *
 * This paper builds on the code and details of the paper: 
 *
 * Classification Using Intersection Kernel SVMs are Efficient, 
 * Subhransu Maji, Alexander C. Berg, Jitendra Malik, CVPR 2008.
 *
 * Version 1.0
 */

#include <stdio.h>
#include "mex.h"
#include "matrix.h"

#if MX_API_VER < 0x07030000
typedef int mwIndex;
#endif

#define MIN(x,y) (x <= y ? x : y)
#define MAX(x,y) (x <= y ? y : x)


static void fake_answer(mxArray *plhs[]){
  plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
}

void exit_with_help(){
  mexPrintf("Usage: [dpscore,dpprev] = mexOptTiered(cu,py,cpx,lambda,upperb,lowerb,tau)");
}

float abs(float x){
  if(x < 0)
    return -x;
  else
    return  x;
       
}


// Find optimal rectangle by exhaustive search
void getOptRectangle(int nlhs, mxArray *plhs[], const mxArray *prhs[]){
  // Input
  float *cu   = (float *)mxGetPr(prhs[0]);
  float *py  = (float *)mxGetPr(prhs[1]);
  float *cpx  = (float *)mxGetPr(prhs[2]);
  double lambda = (double)*mxGetPr(prhs[3]);
  float *upperb = (float*)mxGetPr(prhs[4]);
  float *lowerb = (float*)mxGetPr(prhs[5]);
  double tau = (double)*mxGetPr(prhs[6]);

  // Width and height of the tables
  int h  = (int)mxGetM(prhs[0]);
  int w  = (int)mxGetN(prhs[1]);

  int i, j, k, r, l, t, minInd;
  double minVal, score;

  plhs[0] = mxCreateNumericMatrix(h,w,mxDOUBLE_CLASS, mxREAL);
  plhs[1] = mxCreateNumericMatrix(h,w,mxDOUBLE_CLASS, mxREAL);
  double *dpscore = mxGetPr(plhs[0]);
  double *dpprev = mxGetPr(plhs[1]);
  
  // Set the initial values
  for(i = 0; i < h;i++){
    for( j = 0; j < w; j++){
      dpscore[j*h + i] = 1e10;
      dpprev[j*h + i] = 0;
    }
  }
  
  // Set values for the left most column
  for(i = (int)upperb[0]-1; i < (int)lowerb[0];i++){
    dpscore[i] = (1-lambda)*cu[i] + lambda*(py[i] + cpx[i]);
  }

  // Dynamic programming from the left to right
  for(j = 1 ; j < w; j++){
    for(i = (int)upperb[j]-1; i < (int)lowerb[j];i++){
      minVal = 1e10; 
      minInd = 0;
      r = j*h + i;
      for(k = (int)upperb[j-1]-1; k < (int)lowerb[j-1]; k++){
	l = (j-1)*h + k;
	t = j*h + k;
	score = dpscore[l] + (1-lambda)*cu[r] + lambda*(py[r] + abs(cpx[r] - cpx[t])) + tau*abs(float(k-i));
	if (score < minVal){
	  minVal = score;
	  minInd = k + 1;
	}
      }
      dpscore[r] = minVal;
      dpprev[r] = minInd;
    }
  }
}

// Entry function
void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){
  if(nrhs != 7 || nlhs != 2){
    exit_with_help();
    fake_answer(plhs);
    return;
  }
  getOptRectangle(nlhs, plhs, prhs);
  return;
}
