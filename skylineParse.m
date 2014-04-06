function [label, data] = skylineParse(conf, data)

% Preprocess images to various color formats
data.image.lab  = im2single(applycform(data.im, makecform('srgb2lab')));
data.image.gray = im2double(rgb2gray(data.im));
data.image.rgb  = im2single(data.im);

% Compute super-pixels using SLIC
data.segments = vl_slic(data.image.lab, conf.param.slic.regionSize, conf.param.slic.regularizer);

% Assign segments to the labels (initial segmentation)
data.segLabel = labelSegments(data);

% Compute unary terms
data.unary = unaryTerms(conf, data);

% Compute pairwise terms
data.pairwise = pairwiseTerms(conf.param.pairwise.gamma, data.image.lab);

% Parse buildings into rectangles
data.parse = rectMRF(conf, data);

label = parse2label(data.parse, data);

% Refine upper boundaries
% refinedParse = refinedMRF(conf, data, rectParse);

