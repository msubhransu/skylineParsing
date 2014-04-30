function anno = loadAnno()
% LOADANNO loads all the annotations
%   ANNO = LOADANNO() returns a ANNO strcture that can be later queried to
%   obtain individual annotations. 
%
% Author: Subhransu Maji

conf = skylineConfig();

% Else load annotations
cities = getCities(conf);
anno.meta.cities = cities;
anno.meta.imageSet = {'train','val','test'};

% Loop over directories and load images, annotations, etc
city = [];
count = 0;
for i = 1:length(cities),
    f = dir(fullfile(conf.path.image, cities{i}));
    f(1:2) = [];
    for j = 1:length(f), 
        count = count + 1;
        baseName = f(j).name(1:end-4);
        city(count).image = f(j).name;
        city(count).seeds = [baseName '_fgpixels.mat'];
        city(count).label = ['label_' baseName '.mat'];
        city(count).region = [baseName '_greedy_hz3_cost.mat'];
        city(count).cityId = i;
    end
end

anno.object.image = {city(:).image};
anno.object.seeds = {city(:).seeds};
anno.object.label = {city(:).label};
anno.object.region = {city(:).region};
anno.object.cityId = [city(:).cityId];

% Parse imageSet information
imageSets = anno.meta.imageSet;
anno.object.imageSet = zeros(1, length(anno.object.cityId));
for i = 1:length(imageSets),
    [cities, images] = textread(fullfile(conf.path.imageSet, [imageSets{i} '.txt']), '%s %s');
    citySubset = find(ismember(anno.meta.cities, cities));
    cityId = ismember(anno.object.cityId, citySubset);
    imageId = ismember(anno.object.image, images);
    anno.object.imageSet(cityId & imageId) = i;
end

% Keep only those images with valid ids
valid = anno.object.imageSet > 0;
anno = selectAnno(anno, valid);

% List the names of the cities
function cities = getCities(conf)
f = dir(conf.path.image);
f(1:2) = [];
cities = {f(:).name};