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

