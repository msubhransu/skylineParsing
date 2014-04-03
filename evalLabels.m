function eval = evalLabels(pred, gt)

pred = double(pred);
gt = double(gt);

% 1 background, 2:end are buildings
np = max(pred(:));
ng = max(gt(:));

% Compute the areas of each building
areap = hist(pred(:),np);
areag = hist(gt(:), ng);

intersectMap = sub2ind([np ng], pred(:), gt(:));
counts = hist(intersectMap, np*ng);
common = reshape(counts, np, ng);

% Compute score as the intersection over union
overlaps = zeros(np, ng);
for i = 1:np,
    for j = 1:ng, 
        overlaps(i,j) = common(i,j)/(areap(i) + areag(j)-common(i,j));
    end
end

mao = diag(overlaps); 
eval.mao = mean(mao(2:end));
eval.overlaps = overlaps;

