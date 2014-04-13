function eval = evalLabels(pred, gt, doMatching)
if nargin < 3
    doMatching = false;
end

% Resize prediction to the ground trurth size
pred = imresize(pred, size(gt), 'nearest');

pred = double(pred);
gt = double(gt);

% 1 background, 2:end are buildings
np = max(pred(:));
ng = max(gt(:));

% Compute the areas of each building
areap = hist(pred(:),np);
areag = hist(gt(:), ng);

intersectMap = sub2ind([np ng], pred(:), gt(:));
counts = histc(intersectMap, 1:np*ng);
common = reshape(counts, np, ng);

% Compute score as the intersection over union
nmax = max(ng, np);
overlaps = zeros(nmax, nmax);
for i = 1:np,
    for j = 1:ng, 
        overlaps(i,j) = common(i,j)/(areap(i) + areag(j)-common(i,j)+eps);
    end
end

% Compute scores by matching labels to one another
if ~doMatching, 
    % Labels matched to itself
    assert(np <= ng); 
    mao = diag(overlaps); 
    eval.mao = mean(mao(2:ng));
    eval.overlaps = overlaps;
    eval.np = np;
    eval.ng = ng;
else
    % Match labels to ground truth using hungarian matching
    matchingCosts = -overlaps(2:end,2:end);    
    matching = Hungarian(matchingCosts);
    mao = matching.*overlaps(2:end,2:end);
    % Pick best prediction for each ground truth label
    gtMao = sum(mao, 1);
    eval.mao = mean(gtMao(1:ng-1));
    eval.overlaps = overlaps;
    eval.matching = matching;
    eval.np = np;
    eval.ng = ng;
end
