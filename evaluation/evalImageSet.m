function scores = evalImageSet(conf, anno, imageSet)
imageSetId = find(ismember(anno.meta.imageSet, imageSet));
annoId = find(anno.object.imageSet == imageSetId);
numImages = length(annoId);
fprintf('Evaluating on %i images (imageSet = %s).\n', numImages, imageSet);

scores.annoId = annoId;
scores.mao.slic = zeros(1, numImages);
scores.mao.rect = zeros(1, numImages);
scores.mao.unary = zeros(1, numImages);
scores.conf = conf;

for i = 1:numImages, 
    data = getData(conf, anno, annoId(i));
    gtLabels = data.gtLabels;

    % Rectangular parse
    [parses, data] = skylineParse(conf, data);
    evals = evalLabels(parse2label(parses.rect, data), gtLabels);
    scores.mao.rect(i) = evals.mao;
    
    % Get SLIC parse (seeds projected to slic regions)
    slicSeg = data.segLabel;
    slicSeg(slicSeg == 0) = 1;
    evals = evalLabels(slicSeg, gtLabels);
    scores.mao.slic(i) = evals.mao;
    
    % Get unary parse
    [~,unaryLabel] = min(data.unary.combined, [], 3);
    evals = evalLabels(unaryLabel, gtLabels);
    scores.mao.unary(i) = evals.mao;
    
    fprintf('Image %i: slic %.1f (%.1f), rect %.1f (%.1f) unary %.1f (%.1f)\n\n', i, ...
                scores.mao.slic(i)*100, mean(scores.mao.slic(1:i))*100,...
                scores.mao.rect(i)*100, mean(scores.mao.rect(1:i))*100,...
                scores.mao.unary(i)*100, mean(scores.mao.unary(1:i))*100);
end
