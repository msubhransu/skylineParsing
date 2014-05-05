% Entry code for compiling all the mex files
% Use option -std=c++11 for clang compiler on OSX 10.9
% Use option -largeArrayDims for 64 bit machines
%
% Author: Subhransu Maji

% Create bin directory if it does not exist
if ~exist('bin', 'file')
    mkdir('bin');
end

% Pass additional flags to the cxx compiler
% Set this flag on OSX 10.9 and clang compiler.
% CXXFLAGS='-std=c++11'; 

% On linux machines set this flag to empty
CXXFLAGS=''; 

% Mex code for rectangle parsing
cmd=sprintf('mex -O CXXFLAGS="%s" parse/mexOptRectangle.cc -outdir bin', CXXFLAGS);
eval(cmd);
disp('done compiling..mexOptRectangle.');

% Mex code for tiered parsing
cmf=sprintf('mex -O CXXFLAGS="%s" parse/mexOptTiered.cc -outdir bin', CXXFLAGS);
eval(cmd);
disp('done compiling..mexOptTiered.');

% Mex code for maxflow
cmd=sprintf('mex -O -largeArrayDims CXXFLAGS="%s" extern/maxflow/maxflowmex.cpp extern/maxflow/graph.cpp extern/maxflow/maxflow.cpp  -outdir bin', CXXFLAGS);
eval(cmd);
disp('done compiling..maxflow.');

% Mex code for computing weight matrix
cmd=sprintf('mex -O CXXFLAGS="%s" extern/maxflow/mexComputeWeightMatrix.cc  -outdir bin', CXXFLAGS);
eval(cmd);
disp('done compiling..mexComputeWeightMatrix.');