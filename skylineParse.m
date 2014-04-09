function [parses, data] = skylineParse(conf, data)
[h, w, ~] = size(data.im);
scale = 1;
if max(h,w) > conf.param.image.maxDim
    scale = conf.param.image.maxDim/max(h,w);
    data = resizeData(data, scale);
    fprintf('Resizing image by factor=%.2f [dims %i x %i].\n', scale, round(h*scale), round(w*scale));
end
data.scale = scale;
% Preprocess images to various color formats
data.image.lab   = im2single(applycform(data.im, makecform('srgb2lab')));
data.image.gray = im2double(rgb2gray(data.im));
data.image.rgb   = im2single(data.im);

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
parses = rectangleMRF(conf, data);
