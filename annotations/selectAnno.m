function sanno = selectAnno(anno, subset)
sanno = anno;
sanno.object.image = anno.object.image(subset);
sanno.object.seeds = anno.object.seeds(subset);
sanno.object.label = anno.object.label(subset);
sanno.object.region = anno.object.region(subset);
sanno.object.cityId = anno.object.cityId(subset);
sanno.object.imageSet = anno.object.imageSet(subset);