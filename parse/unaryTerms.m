function unary = unaryTerms(conf, data)
fprintf('Computing unary terms (%i regions)\n', max(data.segLabel(:)));
unary.color = colorScore(conf, data);
assert(~any(isnan(unary.color(:))));

unary.texture = textureScore(conf, data);
assert(~any(isnan(unary.texture(:))));

unary.spatial = spatialScore(conf, data);
assert(~any(isnan(unary.spatial(:))));

% Combine the scores
alpha = conf.param.alpha;
beta = conf.param.beta;
unary.combined = alpha*(beta*unary.color + (1-beta)*unary.texture) + (1-alpha)*unary.spatial;

bgMask = data.segLabel == 1;
[bgi, bgj] = ind2sub([size(data.labels,1) size(data.labels,2)], find(bgMask));
[fgi, fgj] = ind2sub([size(data.labels,1) size(data.labels,2)], find(~bgMask));

% Set all the scores appropriately for the background regions
maxVal = max(abs(unary.combined(:)));
numLabels = max(data.segLabel(:));

bginds = sub2ind(size(data.labels), bgi, bgj, ones(size(bgi)));
fginds = sub2ind(size(data.labels), fgi, fgj, ones(size(fgi)));

% Label 1 is background
unary.combined(bginds) = -maxVal;
unary.combined(fginds) = maxVal;

% Cost of labelling background is high, seeds is low
for i=2:numLabels,
    thisSeeds = data.seeds{i-1};
    numSeeds = size(thisSeeds,1);
    seedinds = sub2ind(size(unary.combined), thisSeeds(:,2), thisSeeds(:,1), double(i)*ones(numSeeds,1));
    unary.combined(seedinds) = -maxVal*100;
end

% Ignore these for memory reasons
unary.color = [];
unary.texture = [];
unary.spatial = [];

%--------------------------------------------------------------------------
%                                                     Compute spatial terms
%--------------------------------------------------------------------------
function score = spatialScore(conf, data)
% Compute the distance from the mean seed pixel
labels = data.segLabel;
numLabels = max(labels(:));
score = zeros([size(labels,1)*size(labels,2) numLabels], 'single');
fprintf(' Spatial (X Dist.):');
tic;
for i = 2:numLabels, 
    seedCtrX = mean(data.seeds{i-1}(:,1));
    dist = abs(repmat((1:size(labels,2))- seedCtrX, size(labels,1),1));
    dist = dist(:);
    score(:,i) = dist/norm(dist);
    fprintf('.');
end
score = reshape(score,[size(labels,1) size(labels,2) numLabels]);
fprintf('[done] %.2fs elapsed.\n', toc);

%--------------------------------------------------------------------------
%                                                        Compute data terms
%--------------------------------------------------------------------------
function score = colorScore(conf, data)
% For each seed region compute a Gaussian mixture model of the LAB vectors
featDim = size(data.image.lab, 3);
feat = reshape(data.image.lab, [size(data.image.lab,1)*size(data.image.lab,2) featDim]);
labels = data.segLabel;
numLabels = max(labels(:));
score = zeros([size(labels,1)*size(labels,2) numLabels], 'single');

fgMask = labels ~= 1;
fgFeat = feat(fgMask, :);
tic;
fprintf(' Color (LAB space):');
uniformNegLogLikelihood = -log(1e-4); %all colors are equally likely?

% Compute negative log likelihood for all the regions
for i = 2:numLabels,
    fprintf('.');
    numPixels = sum(labels == i);
    if numPixels < conf.param.color.numGMMClusters*4,
        score(fgMask, i) = uniformNegLogLikelihood;
        continue;
    end
    regionFeat = feat(labels==i, :);
    numCenters = conf.param.color.numGMMClusters;
    [ctr, id] = vl_kmeans(regionFeat', numCenters, 'distance', 'l2', 'algorithm', 'elkan');
    ctr = ctr'; id = id';
    numCtr = size(ctr, 1);
    
    % Compute covariances
    ctrs = zeros(featDim, numCtr);
    wts  = zeros(1,numCtr);
    covs = zeros(featDim, featDim, numCtr);
    for k=1:numCtr
        thisCtr = regionFeat(id==k,:);        %% Colors belonging to cluster k
        ctrs(:,k) = mean(thisCtr,1)';
        covs(:,:,k) = cov(thisCtr) + eye(featDim)*1e-6; 
        wts(k) = mean(id == k);
    end
    fgDist = clustDistMembership(fgFeat, ctrs, covs, wts);
    score(fgMask,i) = fgDist/norm(fgDist);
end
score = reshape(score,[size(labels,1) size(labels,2) numLabels]);
fprintf('[done] %.2fs elapsed.\n', toc);

%--------------------------------------------------------------------------
%                                                        Compute data terms
%--------------------------------------------------------------------------
function score = textureScore(conf, data)
% Load params of the texton filters (from BSDS segmentation)
no = conf.param.texton.no;
ss = conf.param.texton.ss;
ns = conf.param.texton.ns;
sc = conf.param.texton.sc;
el = conf.param.texton.el;
k  = conf.param.texton.k ;
radius = conf.param.texton.radius;

% Load textons (these are precomputed)
fileName = sprintf('unitex_%.2g_%.2g_%.2g_%.2g_%.2g_%d.mat',no, ss, ns, sc, el, k);
load(fullfile(conf.path.texton, fileName), 'fb', 'tex', 'tsim');           

% Assign textons to pixels in the image
texMap = assignTextons(fbRun(fb, data.image.gray), tex);

% Compute local histograms at each pixel by pooling textons within a radius
feat = getTexture(texMap, k, radius);
featDim = size(feat, 2);

% Compute GMM clusters for each region and assign log-likelihood
labels = data.segLabel;
numLabels = max(labels(:));
score = zeros([size(labels,1)*size(labels,2) numLabels], 'single');

fgMask = labels ~= 1;
fgFeat = feat(fgMask, :);
tic;
fprintf(' Texture (Textons):');
uniformDistance = 0.5; %all textures

% Compute negative log likelihood for all the regions
for i = 2:numLabels,
    fprintf('.');
    numPixels = sum(labels == i);
    if numPixels < conf.param.texture.numGMMClusters*4,
        score(fgMask, i) = uniformDistance;
        continue;
    end
    regionFeat = feat(labels==i, :);
    numCenters = conf.param.color.numGMMClusters;
    [ctr, id] = vl_kmeans(regionFeat', numCenters, 'distance', 'l2', 'algorithm', 'elkan');
    ctr = ctr'; id = id';
    numCtr = size(ctr, 1);
    
    % Compute covariances
    ctrs = zeros(featDim, numCtr);
    wts  = zeros(1,numCtr);
    covs = zeros(featDim, featDim, numCtr);
    for k=1:numCtr
        thisCtr = regionFeat(id==k,:);        %% Colors belonging to cluster k
        ctrs(:,k) = mean(thisCtr,1)';
        covs(:,:,k) = cov(thisCtr) + eye(featDim)*1e-6; 
        wts(k) = mean(id == k);
    end

    fgDist = textureDistMembership(fgFeat, ctrs);
    score(fgMask,i) = fgDist/norm(fgDist);
end
score = reshape(score,[size(labels,1) size(labels,2) numLabels]);
fprintf('[done] %.2fs elapsed.\n', toc);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% Helper Functions declarations  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [dist, ind] = clustDistMembership(x, ctr, covs, wts)
numCtr = size(ctr,2);
num = size(x,1);
tmpDist = zeros(num, numCtr);
for k = 1:numCtr
    thisCtr = ctr(:,k);
    thisCov = covs(:,:,k);
    w = wts(1,k);
    dd = x - repmat(thisCtr',num,1);
    tmpDist(:,k) = -log((w / sqrt(det(thisCov))) * exp(-( sum( ((dd/thisCov) .* dd),2) /2)));
end
[dist, ind] = min(tmpDist,[],2);
maxDist = max(dist(dist~=inf));
dist(dist==inf) = maxDist;

function [TDist, TInd] = textureDistMembership(TexHist,TClusters)
NumFClusters = size(TClusters,2);
numULabels = size(TexHist,1);

Ttmp = zeros(numULabels, NumFClusters);

for k=1:NumFClusters
    M = TClusters(:,k);
    Num = (TexHist - repmat(M',numULabels,1)).^2;
    Den = (TexHist + repmat(M',numULabels,1) + eps);
    Ttmp(:,k) = sum(Num ./ Den,2); 
end
[TDist, TInd] = min(Ttmp,[],2);
