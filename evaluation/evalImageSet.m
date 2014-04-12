function scores = evalImageSet(conf, anno, imageSet)
imageSetId = find(ismember(anno.meta.imageSet, imageSet));
annoId = find(anno.object.imageSet == imageSetId);
numImages = length(annoId);
fprintf('Evaluating on %i images (imageSet = %s).\n', numImages, imageSet);

scores.annoId = annoId;
scores.mao.tiered = zeros(1, numImages);
scores.mao.slic = zeros(1, numImages);
scores.mao.rect = zeros(1, numImages);
scores.mao.refined = zeros(1, numImages);
scores.mao.unary = zeros(1, numImages);
scores.conf = conf;

for i = 1:numImages,
    data = getData(conf, anno, annoId(i));
    gtLabels = data.gtLabels;

    % Rectangular parse
    [parses, data] = skylineParse(conf, data);
    evals = evalLabels(parse2label(parses.rect, data), gtLabels);
    scores.mao.rect(i) = evals.mao;

    % Refined parse
    evals = evalLabels(parse2label(parses.refined, data), gtLabels);
    scores.mao.refined(i) = evals.mao;
    
        % Get tiered parse
    parses = tieredMRF(conf, data);
    evals = evalLabels(parse2label(parses.tiered, data), gtLabels);
    scores.mao.tiered(i) = evals.mao;
    
    % Get SLIC parse (seeds projected to slic regions)
    slicSeg = data.segLabel;
    slicSeg(slicSeg == 0) = 1;
    evals = evalLabels(slicSeg, gtLabels);
    scores.mao.slic(i) = evals.mao;
    
    % Get unary parse
    [~,unaryLabel] = min(data.unary.combined, [], 3);
    evals = evalLabels(unaryLabel, gtLabels);
    scores.mao.unary(i) = evals.mao;
    
    % Get MRF parse
    mrfLabel = standardMRF(conf, data);
    evals = evalLabels(mrfLabel, gtLabels);
    scores.mao.mrf(i) = evals.mao;
    
    fprintf('Image %i: rect %.1f (%.1f), refined %.1f (%.1f), tiered %.1f (%.1f), unary %.1f (%.1f),  mrf %.1f (%.1f)\n\n', i, ...
                scores.mao.rect(i)*100, mean(scores.mao.rect(1:i))*100,...
                scores.mao.refined(i)*100, mean(scores.mao.refined(1:i))*100,...
                scores.mao.tiered(i)*100, mean(scores.mao.tiered(1:i))*100,...
                scores.mao.unary(i)*100, mean(scores.mao.unary(1:i))*100,...
                scores.mao.mrf(i)*100, mean(scores.mao.mrf(1:i))*100);
end
