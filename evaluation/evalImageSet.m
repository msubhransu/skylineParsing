function scores = evalImageSet(conf, anno, imageSet)
imageSetId = find(ismember(anno.meta.imageSet, imageSet));
annoId = find(anno.object.imageSet == imageSetId);
numImages = length(annoId);
fprintf('Evaluating on %i images (imageSet = %s).\n', numImages, imageSet);

scores.annoId = annoId;
scores.mao.slic = zeros(1, numImages);
scores.mao.rect = zeros(1, numImages);
scores.conf = conf;

for i = 1:numImages, 
    data = getData(conf, anno, annoId(i));
    gtLabels = data.gtLabels;
    [parse, data] = skylineParse(conf, data);
    evals = evalLabels(parse2label(parse, data), gtLabels);
    scores.mao.rect(i) = evals.mao;
    slicSeg = data.segLabel;
    slicSeg(slicSeg == 0) = 1;
    evals = evalLabels(slicSeg, gtLabels);
    scores.mao.slic(i) = evals.mao;
    
    fprintf('Image %i: slic %.2f (%.2f), rect %.2f (%.2f) \n\n', i, ...
                scores.mao.slic(i)*100, mean(scores.mao.slic(1:i))*100,...
                scores.mao.rect(i)*100, mean(scores.mao.rect(1:i))*100);
end
