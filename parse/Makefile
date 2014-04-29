# This Makefile is used under Linux

MATLABDIR ?= /Applications/MATLAB_R2011a.app
CXX ?= g++
CFLAGS = -std=c++11 -Wall -Wconversion -O3 -fPIC -I$(MATLABDIR)/extern/include

MEX = $(MATLABDIR)/bin/mex
MEX_OPTION = CC\#$(CXX) CXX\#$(CXX) CFLAGS\#"$(CFLAGS)" CXXFLAGS\#"$(CFLAGS)"
# comment the following line if you use MATLAB on 32-bit computer
MEX_OPTION += -largeArrayDims
MEX_EXT = $(shell $(MATLABDIR)/bin/mexext)

all:    binary

binary: mexOptRectangle.$(MEX_EXT) mexOptTiered.$(MEX_EXT)

mexOptRectangle.$(MEX_EXT): mexOptRectangle.cc
	$(MEX) $(MEX_OPTION) mexOptRectangle.cc

mexOptTiered.$(MEX_EXT): mexOptTiered.cc
	$(MEX) $(MEX_OPTION) mexOptTiered.cc
