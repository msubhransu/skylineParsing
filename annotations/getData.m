function data = getData(conf, anno, i)

% Load annotations corresponding to this data
city = anno.meta.cities{anno.object.cityId(i)};
im = imread(fullfile(conf.path.image, city, anno.object.image{i}));
load(fullfile(conf.path.labels, city, anno.object.label{i}));
load(fullfile(conf.path.regions, city, anno.object.region{i}));
load(fullfile(conf.path.seeds, city, anno.object.seeds{i}));

% Copy data, image, labels, seeds
data.city = city;
data.im = im;
data.labels = labels;
data.region = sanitizePath(opt_path1);
data.seeds = fgpixels;

% Assign labels to seeds (and vice versa)
numSeeds = length(data.seeds);
numLabels = length(unique(data.labels(:)));
seed2label = -ones(1, numSeeds);
label2seed = -ones(1, numLabels);
for i = 1:numSeeds, 
    seedxy = data.seeds{i};
    seedLabels = data.labels(sub2ind(size(data.labels), seedxy(:,2), seedxy(:,1)));
    seed2label(i) = mode(seedLabels);
    label2seed(seed2label(i)+1) = i; % Labels start at zero 
end
data.seed2label = seed2label;
data.label2seed = label2seed;
assert(all(data.seed2label >= 0));


function newPath = sanitizePath(path)
newPath(:,1) = min(path(:,1), path(:,2));
newPath(:,2) = max(path(:,1), path(:,2));

% If paths touch then add a small margin
touching = newPath(:,2) - newPath(:,1) < 3; 
newPath(touching,1) = newPath(touching,1) - 2;
newPath(touching,2) = newPath(touching,2) + 2;