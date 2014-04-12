function eval = evalLabels(pred, gt)

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
overlaps = zeros(ng, ng);
for i = 1:np,
    for j = 1:ng, 
        overlaps(i,j) = common(i,j)/(areap(i) + areag(j)-common(i,j)+eps);
    end
end

mao = diag(overlaps); 
eval.mao = mean(mao(2:end));
eval.overlaps = overlaps;

