function [label, data] = skylineParse(conf, data)

% Preprocess images to various color formats
data.image.lab  = im2single(applycform(data.im, makecform('srgb2lab')));
data.image.gray = rgb2gray(data.im)/255;
data.image.rgb  = im2single(data.im);

% Compute super-pixels using SLIC
data.segments = vl_slic(data.image.lab, conf.slic.regionSize, conf.slic.regularizer);

% Compute data terms
data.score = localScore(conf, data);

% Label the regions
label = [];

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



function score = textureScore(conf, data)

% Load params of the texton filters (from BSDS segmentation)
no = conf.param.texton.no;
ss = conf.param.texton.ss;
ns = conf.param.texton.ns;
sc = conf.param.texton.sc;
el = conf.param.texton.el;
k  = conf.param.texton.k ;

% Load textons (these are precomputed)
fileName = sprintf('unitex_%.2g_%.2g_%.2g_%.2g_%.2g_%d.mat',no, ss, ns, sc, el, k);
load(fullfile(conf.path.texton, fileName), 'fb', 'tex', 'tsim');           

% Assign textons to pixels in the image
texMap = assignTextons(fbRun(fb, data.image.gray), tex);
texHist = getTexture(texMap, 32, 20); % Figure out what 20 is 