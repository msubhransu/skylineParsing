% Entry code for compiling all the mex files
% Use option -std=c++11 for clang compiler on OSX 10.9
% Use option -largeArrayDims for 64 bit machines
%
% Author: Subhransu Maji

% Create bin directory if it does not exist
if ~exist('bin', 'file')
    mkdir('bin');
end

% Mex code for rectangle parsing
mex -O CXXFLAGS="-std=c++11" parse/mexOptRectangle.cc -outdir bin
disp('done compiling..mexOptRectangle.');

% Mex code for tiered parsing
mex -O CXXFLAGS="-std=c++11" parse/mexOptTiered.cc -outdir bin
disp('done compiling..mexOptTiered.');

% Mex code for maxflow
mex -O -largeArrayDims CXXFLAGS="-std=c++11" extern/maxflow/maxflowmex.cpp extern/maxflow/graph.cpp extern/maxflow/maxflow.cpp  -outdir bin
disp('done compiling..maxflow.');

% Mex code for computing weight matrix
mex -O CXXFLAGS="-std=c++11" extern/maxflow/mexComputeWeightMatrix.cc  -outdir bin
disp('done compiling..mexComputeWeightMatrix.');
