% Here is a demo to illustrate loading annotations and displaying them
%
% Author: Subhransu Maji

anno = loadAnno();
fprintf('Loaded %i annotations.\n', length(anno.object.image));

%% Show annotations from Chicago
cityName = 'Chicago';
cityId = find(ismember(anno.meta.cities, cityName));
disp('Showing Chicago annotations...press "esc" to quit.');
showAnno(selectAnno(anno, anno.object.cityId == cityId));

%% Below are some more examples (commented out)
%Show all annotations in the dataset
%disp('Showing all annotations...press "esc" key to quit.');
%showAnno(anno);

%Show annotations in the 'training' set
%disp('Showing training annotations...press "esc" key to quit.');
%showAnno(anno, 'train');