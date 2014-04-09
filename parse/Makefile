# This Makefile is used under Linux

MATLABDIR ?= /Applications/MATLAB_R2011a.app
CXX ?= g++
CFLAGS = -Wall -Wconversion -O3 -fPIC -I$(MATLABDIR)/extern/include

MEX = $(MATLABDIR)/bin/mex
MEX_OPTION = CC\#$(CXX) CXX\#$(CXX) CFLAGS\#"$(CFLAGS)" CXXFLAGS\#"$(CFLAGS)"
# comment the following line if you use MATLAB on 32-bit computer
MEX_OPTION += -largeArrayDims
MEX_EXT = $(shell $(MATLABDIR)/bin/mexext)

all:    binary

binary: mexOptRectangle

mexOptRectangle: mexOptRectangle.cc
	$(MEX) $(MEX_OPTION) mexOptRectangle.cc
