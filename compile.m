mex -O parse/mexOptRectangle.cc -outdir bin
disp('done compiling..mexOptRectangle.');

mex -O parse/mexOptTiered.cc -outdir bin
disp('done compiling..mexOptRectangle.');

mex -O -largeArrayDims extern/maxflow/maxflowmex.cpp extern/maxflow/graph.cpp extern/maxflow/maxflow.cpp  -outdir bin
disp('done compiling..maxflow.');

mex -O extern/maxflow/mexComputeWeightMatrix.cc  -outdir bin
disp('done compiling..mexComputeWeightMatrix');



