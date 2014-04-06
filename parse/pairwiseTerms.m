function pairwise = pairwiseTerms(gamma, image)
% Compute image differences
[h,w, ~] = size(image);
xx = zeros(h,w,'single');
yy = zeros(h,w,'single');
dx = image(1:end,2:end,:)-image(1:end,1:end-1,:);
dy = image(1:end-1,1:end,:)-image(2:end,1:end,:);
xx(1:end, 2:end) = exp(-gamma*(sum(dx.^2,3)));
yy(2:end, 1:end) = exp(-gamma*(sum(dy.^2,3)));

pairwise.xx = single(xx);
pairwise.yy = single(yy);
