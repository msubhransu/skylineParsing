%% Loads annotations and displays them
anno = loadAnno();

%% Show all annotations
disp('Showing all annotations...press Esc to quit.');
showAnno(anno);

%% Show annotations in the training set
disp('Showing training annotations...press Esc to quit.');
showAnno(anno, 'train');

%% Show annotations from Chicago
cityId = find(ismember(anno.meta.cities, 'Chicago'));
disp('Showing Chicago annotations...press Esc to quit.');
showAnno(selectAnno(anno, anno.object.cityId == cityId));