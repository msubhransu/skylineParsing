function sanno = selectAnno(anno, subset)
sanno = anno;
sanno.object.image = anno.object.image(subset);
sanno.object.seeds = anno.object.seeds(subset);
sanno.object.gtLabel = anno.object.gtLabel(subset);
sanno.object.cityId = anno.object.cityId(subset);
sanno.object.imageSet = anno.object.imageSet(subset);