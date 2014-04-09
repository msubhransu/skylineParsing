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
  mexPrintf("Usage: rectangle = mexOptRectangle(cu,cpy,cpx,lambda,upperb,lowerb,width,seedymin,stepsize)");
}

float getMinVal(float* vals, int s, int e){
  float minValue = vals[s];
  for(int i = s+1; i <= e; i++){
    if(vals[i] < minValue){
      minValue = vals[i];
    }
  }
  return minValue;
}

float getMaxVal(float* vals, int s, int e){
  float maxValue = vals[s];
  for(int i = s+1; i <= e; i++){
    if(vals[i] > maxValue){
      maxValue = vals[i];
    }
  }
  return maxValue;
}

// Find optimal rectangle by exhaustive search
void getOptRectangle(int nlhs, mxArray *plhs[], const mxArray *prhs[]){
  // Input
  float *cu   = (float *)mxGetPr(prhs[0]);
  float *cpy  = (float *)mxGetPr(prhs[1]);
  float *cpx  = (float *)mxGetPr(prhs[2]);
  float lambda = (float)*mxGetPr(prhs[3]);
  float *upperb = (float*)mxGetPr(prhs[4]);
  float *lowerb = (float*)mxGetPr(prhs[5]);
  int width = (int)*mxGetPr(prhs[6]);
  int xmin = (int)*mxGetPr(prhs[7]);
  int xmax = (int)*mxGetPr(prhs[8]);
  int ymin = (int)*mxGetPr(prhs[9]);
  int stepSize = (int)*mxGetPr(prhs[10]);
  
  // Width and Height of the tables
  int h  = (int)mxGetM(prhs[0]);
  int w  = (int)mxGetN(prhs[1]);

  double minScore = 1e10; // large value
  double unaryScore, pairwiseScore, score;
  int left=-1, top=-1, right=-1; // optimal values
  
  int l, r, t, li, ri;
  int tmin, tmax;
  int count = 0;
  for(l = 0; l < xmin;l+=stepSize){
    for(r = MAX(xmax,l+width); r < w; r+=stepSize){
      tmin = (int)getMinVal(upperb, l, r)-1;
      tmax = (int)MIN(getMaxVal(lowerb, l, r), ymin)-1;
      
      for(t = tmin; t <= tmax; t+=stepSize){
	li = l*h + t; 
	ri = r*h + t;
	unaryScore = cu[ri]-cu[li];
	pairwiseScore = cpy[ri]-cpy[li]+cpx[li]+cpx[ri];
	score = (1-lambda)*unaryScore + lambda*pairwiseScore;
	if(score < minScore){
	  minScore = score;
	  left = l; 
	  right = r;
	  top = t;
	}
	count++;
      }
    }
  }
  // Output
  plhs[0] = mxCreateNumericMatrix(3,1,mxDOUBLE_CLASS, mxREAL);
  double *rect = mxGetPr(plhs[0]);
  rect[0] = double(left+1);
  rect[1] = double(top+1);
  rect[2] = double(right+1);
}

// Entry function
void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){
  if(nrhs != 11 || nlhs != 1){
    exit_with_help();
    fake_answer(plhs);
    return;
  }
  getOptRectangle(nlhs, plhs, prhs);
  return;
}
