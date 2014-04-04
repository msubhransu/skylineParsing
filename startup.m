% Startup script for setting up global variables and paths to various code
% directories

addpath annotations;
addpath extern/pbDetector;
addpath extern/textons;
disp('Added paths..\n');

% Set this to the path of the VLFEAT
vlFeatPath='../../vlfeat';
run([vlFeatPath '/toolbox/vl_setup.m']);
disp('Setup vlfeat');

disp('Startup done.');