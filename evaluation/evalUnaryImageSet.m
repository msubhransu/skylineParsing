function scores = evalUnaryImageSet(conf, anno, imageSet)
imageSetId = find(ismember(anno.meta.imageSet, imageSet));
annoId = find(anno.object.imageSet == imageSetId);
numImages = length(annoId);
fprintf('Evaluating on %i images (imageSet = %s).\n', numImages, imageSet);

scores.annoId = annoId;
scores.mao.combined = zeros(1, numImages);
scores.mao.nocolor = zeros(1, numImages);
scores.mao.notexture = zeros(1, numImages);
scores.mao.nospatial = zeros(1, numImages);
scores.conf = conf;

% Weights for color, texture and spatial terms
alpha = conf.param.alpha;
beta = conf.param.beta;

% Keep intermediate unary potentials
conf.keepUnary = true;

for i = 1:numImages,
    data = getData(conf, anno, annoId(i));
    gtLabels = data.gtLabels;
    
    % Compute unary potentials
    data = prepareData(conf, data);

    % Combined
    [~,unaryLabel] = min(data.unary.combined, [], 3);
    evals = evalLabels(unaryLabel, gtLabels);
    scores.mao.combined(i) = evals.mao;

    % No color
    [~,unaryLabel] = min(alpha*data.unary.texture + (1-alpha)*data.unary.spatial, [], 3);
    evals = evalLabels(unaryLabel, gtLabels);
    scores.mao.nocolor(i) = evals.mao;

    % No texture
    [~,unaryLabel] = min(alpha*data.unary.color + (1-alpha)*data.unary.spatial, [], 3);
    evals = evalLabels(unaryLabel, gtLabels);
    scores.mao.notexture(i) = evals.mao;
    
    % No spatial
    [~,unaryLabel] = min(beta*data.unary.color + (1-beta)*data.unary.texture, [], 3);
    evals = evalLabels(unaryLabel, gtLabels);
    scores.mao.nospatial(i) = evals.mao;
    
    fprintf('Image %i: combined %.1f (%.1f), -color %.1f (%.1f), -texture %.1f (%.1f), -spatial %.1f (%.1f)\n\n', i, ...
                scores.mao.combined(i)*100, mean(scores.mao.combined(1:i))*100,...
                scores.mao.nocolor(i)*100, mean(scores.mao.nocolor(1:i))*100,...
                scores.mao.notexture(i)*100, mean(scores.mao.notexture(1:i))*100,...
                scores.mao.nospatial(i)*100, mean(scores.mao.nospatial(1:i))*100);
end
