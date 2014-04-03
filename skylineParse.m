function [label, data] = skylineParse(conf, data)

% Preprocess images to various color formats
data.image.lab  = im2single(applycform(data.im, makecform('srgb2lab')));
data.image.gray = rgb2gray(data.im)/255;
data.image.rgb  = im2single(data.im);

% Compute super-pixels using SLIC
data.segments = vl_slic(data.image.lab, conf.param.slic.regionSize, conf.param.slic.regularizer);

% Assign segments to the labels (initial segmentation)
segLabel = labelSegments(data);

% Compute data terms
data.score = localScore(conf, data);

% Label the regions
label = [];

%--------------------------------------------------------------------------
%                                                        Perform initial
%                                                        labelling
%--------------------------------------------------------------------------
function label = labelSegments(data)
% Assign each seed its majority label
% 1 backgroud, 2 unknown, 3:N+2 buildings
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
    if maxVal == 0
        label(data.segments == i) = 2;
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
score.color = colorScore(conf, data);
score.texture = textureScore(conf, data);
score.spatial = spatialScore(conf, data);

% Perform a weighted combintation of the scores
alpha = conf.param.alpha;
beta = conf.param.beta;
score.combined = alpha*(beta*score.color + (1-beta)*score.texture) + (1-alpha)*score.spatial;



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
texHist = getTexture(texMap, k, radius);
