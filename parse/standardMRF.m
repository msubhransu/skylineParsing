function label = standardMRF(conf, data)
unary = data.unary;
numLabels = size(unary.combined,3);

% Cost of labelling background is high, seeds is low
bgMask = data.segLabel == 1;
[bgi, bgj] = ind2sub([size(data.labels,1) size(data.labels,2)], find(bgMask));
[fgi, fgj] = ind2sub([size(data.labels,1) size(data.labels,2)], find(~bgMask));

bginds = sub2ind(size(data.labels), bgi, bgj, ones(size(bgi)));
fginds = sub2ind(size(data.labels), fgi, fgj, ones(size(fgi)));

% Label 1 is background
unary.combined(bginds) = -1e10;
unary.combined(fginds) = 1e10;

for i=2:numLabels,
    thisSeeds = data.seeds{i-1};
    numSeeds = size(thisSeeds,1);
    seedinds = sub2ind(size(unary.combined), thisSeeds(:,2), thisSeeds(:,1), double(i)*ones(numSeeds,1));
    unary.combined(seedinds) = -1e10;
end

numIter = 2*numLabels;
[~,label] = min(unary.combined, [], 3);

lambda = conf.param.pairwise.lambda;
unaryWeight = (1-lambda)/lambda;

% Loop over the data and perform labelling
[ty, tx,~] = size(data.im);
nv = tx*ty;
T = zeros(nv, 2);
W = computeWeightMatrix(data.im);
[jj,ii] = meshgrid(1:tx, 1:ty);

if conf.display
    figure(1); clf;
    imagesc(label); axis image off;
end

fprintf('standard MRF:..');
tic;
for i  = 1:numIter, 
    labelInd = mod(i, numLabels) + 1;
    fgmask = label == labelInd;
    
    % Get the scores for the figure and background
    fgdata = unaryWeight*unary.combined(:,:,labelInd);
    bginds = sub2ind(size(unary.combined), ii(:), jj(:), label(:));
    bgdata = unaryWeight*unary.combined(bginds);
    T(:,2) = bgdata(:);
    T(:,1) = fgdata(:);
    T(fgmask, 2) = 1e10;
    T = sparse(T);
    [~, currLabel] = maxflow(W, T);
    label(currLabel > 0) = labelInd;
    
    % Display labellings
    if conf.display
        figure(1);
        imagesc(label); axis image off;
        title(sprintf('standard MRF: updating: iter %i/%i', i, numIter),'fontSize',16);
    end
end
fprintf('%.2fs elapsed.\n', toc);