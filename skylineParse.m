function [label, data] = skylineParse(conf, data)

% Preprocess images to various color formats
data.image.lab  = im2single(applycform(data.im, makecform('srgb2lab')));
data.image.gray = im2double(rgb2gray(data.im));
data.image.rgb  = im2single(data.im);

% Compute super-pixels using SLIC
data.segments = vl_slic(data.image.lab, conf.param.slic.regionSize, conf.param.slic.regularizer);

% Assign segments to the labels (initial segmentation)
data.segLabel = labelSegments(data);

% Compute data terms
data.score = localScore(conf, data);

% Label the regions
label = [];

%--------------------------------------------------------------------------
%                                                 Perform initial labelling
%--------------------------------------------------------------------------
function label = labelSegments(data)
% Assign each seed its majority label
% 1 backgroud, 0 unknown, 2:N+1 buildings
numSeeds = length(data.seeds);
numSegments = max(data.segments(:));
seed2segment = zeros(numSeeds, numSegments);
label = zeros(size(data.labels), 'uint32');

% Create a seed map
for i = 1:length(data.seeds), 
    fg = data.seeds{i}; %x, y format
    pixelInd = sub2ind(size(label), fg(:,2), fg(:,1));
    segmentId = data.segments(pixelInd);
    for j = 1:length(segmentId), 
        seed2segment(i,segmentId(j)) =  seed2segment(i,segmentId(j)) + 1;
    end
end

% Assign labels to segments
for i = 1:numSegments,
    [maxVal, maxInd] = max(seed2segment(:,i));
    if maxVal == 0 % the superpixel has no seeds
        label(data.segments == i) = 0;
    else
        label(data.segments == i) = maxInd + 1;
    end
end

% All pixels above or below the middle region are background
for i = 1:size(label,2)
    label(1:data.region(i,1),i) = 1;
    label(data.region(i,2):end,i) = 1;
end

%--------------------------------------------------------------------------
%                                                        Compute data terms
%--------------------------------------------------------------------------
function score = localScore(conf, data)
fprintf('Computing data terms (%i regions)\n', max(data.segLabel(:)));
score.color = colorScore(conf, data);
score.texture = textureScore(conf, data);
score.spatial = spatialScore(conf, data);

% Combine the scores
alpha = conf.param.alpha;
beta = conf.param.beta;
score.combined = alpha*(beta*score.color + (1-beta)*score.texture) + (1-alpha)*score.spatial;

bgMask = data.segLabel == 1;
[bgi, bgj] = ind2sub([size(data.labels,1) size(data.labels,2)], find(bgMask));
[fgi, fgj] = ind2sub([size(data.labels,1) size(data.labels,2)], find(~bgMask));

% Set all the scores appropriately for the background regions
maxVal = max(score.combined(:));
numLabels = max(data.segLabel(:));

bginds = sub2ind(size(data.labels), bgi, bgj, ones(size(bgi)));
fginds = sub2ind(size(data.labels), fgi, fgj, ones(size(fgi)));

% Label 1 is background
score.combined(bginds) = -1;
score.combined(fginds) = maxVal;

% Cost of labelling background is high
for i=2:numLabels,
    bginds = sub2ind(size(score.combined), bgi, bgj, double(i)*ones(size(bgi)));
    score.combined(bginds) = 0;
end

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
    numPixels = sum(labels == i);
    if numPixels < conf.param.color.numGMMClusters*4,
        score(fgMask, i) = uniformNegLogLikelihood;
        continue;
    end
    regionFeat = feat(labels==i, :);

    % Compute centers using k-means
    [ctr, id] = vl_kmeans(regionFeat', conf.param.color.numGMMClusters, 'distance', 'l2', 'algorithm', 'elkan');
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
    fprintf('.');
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
    numPixels = sum(labels == i);
    if numPixels < conf.param.texture.numGMMClusters*4,
        score(fgMask, i) = uniformDistance;
        continue;
    end
    regionFeat = feat(labels==i, :);

    % Compute centers using k-means
    [ctr, id] = vl_kmeans(regionFeat', conf.param.texture.numGMMClusters, 'distance', 'l2', 'algorithm', 'elkan');
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
    fprintf('.');
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
