function [parse, data] = skylineParse(conf, data)

% Preprocess images to various color formats
data.image.lab  = im2single(applycform(data.im, makecform('srgb2lab')));
data.image.gray = im2double(rgb2gray(data.im));
data.image.rgb  = im2single(data.im);

% Compute super-pixels using SLIC
fprintf('Computing SLIC segmentation..')
tic;
data.segments = vl_slic(data.image.lab, conf.param.slic.regionSize, conf.param.slic.regularizer);
fprintf('[done] %i segments. %.2fs elapsed.\n', max(data.segments(:)),toc);

% Assign segments to the labels (initial segmentation)
data.segLabel = labelSegments(data);

% Compute unary terms
data.unary = unaryTerms(conf, data);

% Compute pairwise terms
data.pairwise = pairwiseTerms(conf.param.pairwise.gamma, data.image.lab);

% Parse buildings into rectangles
fprintf('Rectangular parsing..');
parse = rectMRF(conf, data);
