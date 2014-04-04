function conf = skylineConfig()
% Sets all the global variables and paths to various datasets
conf.path.dataset = '../data';  % Set this to the path where you have downloaded the data
conf.path.cache = '../cache'; % Set this to where to cache intermediate results
conf.path.anno = fullfile(conf.path.cache, 'anno.mat');
conf.path.image = fullfile(conf.path.dataset, 'images');
conf.path.labels = fullfile(conf.path.dataset, 'labels');
conf.path.regions = fullfile(conf.path.dataset, 'regions');
conf.path.seeds = fullfile(conf.path.dataset, 'seeds');
conf.path.imageSet = fullfile(conf.path.dataset, 'imageSets');
conf.path.texton = fullfile(conf.path.dataset, 'textons');

% SLIC segmentation params
conf.param.slic.regionSize = 30;
conf.param.slic.regularizer = 0.001;

% Texton library parameters
conf.param.texton.no = 6;      %
conf.param.texton.ss = 1;      %
conf.param.texton.ns = 2;      %
conf.param.texton.sc = sqrt(2);%
conf.param.texton.el = 2;      %
conf.param.texton.k  = 32;     % number of textons in the library
conf.param.texton.radius = 20; % radius of region for histogram computation


conf.param.color.numGMMClusters = 3;
conf.param.texture.numGMMClusters = 3;

conf.param.alpha = 0.3;
conf.param.beta = 0.5;