function scores = evalImageSetAuto(conf, anno, imageSet)
% Set random seed for repeatability
rng('default'); 

imageSetId = find(ismember(anno.meta.imageSet, imageSet));
annoId = find(anno.object.imageSet == imageSetId);
numImages = length(annoId);
fprintf('Evaluating on %i images (imageSet = %s).\n', numImages, imageSet);

scores.annoId = annoId;
scores.mao.tiered = zeros(1, numImages);
scores.mao.rect = zeros(1, numImages);
scores.mao.refined = zeros(1, numImages);
scores.mao.base = zeros(1, numImages);
scores.conf = conf;

for i = 1:numImages, 
    data = getData(conf, anno, annoId(i));
    gtLabels = data.gtLabels;
    
    % Prepare data with automatic seed initialization
    data = prepareData(conf, data, true);

    % Rectangular parse
    parses = skylineParse(conf, data, 'rectangle');
    evals = evalLabels(parse2label(parses.rect, data), gtLabels, true);
    scores.mao.rect(i) = evals.mao;

    % Refined parse (part of rectangle parse)
    evals = evalLabels(parse2label(parses.refined, data), gtLabels, true);
    scores.mao.refined(i) = evals.mao;
    
    % Get tiered parse
    parses = skylineParse(conf, data, 'tiered');
    evals = evalLabels(parse2label(parses.tiered, data), gtLabels, true);
    scores.mao.tiered(i) = evals.mao;
    
    % Get SLIC parse
    slicSeg = data.segments;
    for j = 1:size(slicSeg,2)
        slicSeg(1:data.region(i,1),i) = 1;
        slicSeg(data.region(i,2):end,i) = 1;
    end
    slicSeg(slicSeg < 1) = 1;
    evals = evalLabels(slicSeg, gtLabels, true);
    scores.mao.slic(i) = evals.mao;
    
    % Get unary parse
    [~,unaryLabel] = min(data.unary.combined, [], 3);
    evals = evalLabels(unaryLabel, gtLabels, true);
    scores.mao.unary(i) = evals.mao;
    
    fprintf('Image %i: rect %.1f (%.1f), refined %.1f (%.1f), tiered %.1f (%.1f), slic %.1f (%.1f) unary %.1f (%.1f)\n\n', i, ...
                scores.mao.rect(i)*100, mean(scores.mao.rect(1:i))*100,...
                scores.mao.refined(i)*100, mean(scores.mao.refined(1:i))*100,...
                scores.mao.tiered(i)*100, mean(scores.mao.tiered(1:i))*100,...
                scores.mao.slic(i)*100, mean(scores.mao.slic(1:i))*100,...
                scores.mao.unary(i)*100, mean(scores.mao.unary(1:i))*100);
end
