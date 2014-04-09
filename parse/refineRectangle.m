function [buildingUpper, rect] = refineRectangle(conf, data, parse, ind, label)
% Compute the bounds of this seed and region of interest
[h,w,~]=size(data.unary.combined);
thisSeed = data.seeds{ind};
xx = thisSeed(:,1); 
yy = thisSeed(:,2);
xmin = max(1, min(xx) - conf.param.building.maxWidth/2);
xmax = min(w, max(xx) + conf.param.building.maxWidth/2);
ymin = max(1, min(parse.upper(xmin:xmax))-conf.param.building.search.deltay);
ymax = min(h, max(parse.lower(xmin:xmax)));

% Crop the unary and pairwise terms around the building of interest
unaryInd = ind + 1;
fg = data.unary.combined(ymin:ymax,xmin:xmax,unaryInd);
regionLabel = label(ymin:ymax, xmin:xmax);
fgmask = regionLabel == unaryInd;

% Estimate the labels for the background regions
bglabel = regionLabel;
bglabel(fgmask) = 0; 
for i = 1:size(bglabel,2)
    minInd = find(bglabel(:,i)==0,1);
    if ~isempty(minInd)
        if minInd == 1
            bglabel(bglabel(:,i)==0,i) = 1; % background
        else
            upperLabel = bglabel(minInd-1,i);
            bglabel(bglabel(:,i)==0,i) = upperLabel;
        end
    end
end

% Compute unary potentials for background regions
regionUnary = data.unary.combined(ymin:ymax, xmin:xmax, :);

[jj,ii] = meshgrid(1:xmax-xmin+1, 1:ymax-ymin+1);
bgind = sub2ind(size(regionUnary),ii(:), jj(:), double(bglabel(:)));
bg = reshape(regionUnary(bgind), size(ii));

% Compute upper and lower bounds for this tier
orderInd = find(parse.order == ind);
if orderInd == 1, 
    prevUpper = parse.lower;
else
    prevInd = parse.order(orderInd-1);
    prevUpper = parse.tiers(prevInd,:);
end
thisUpper = single(parse.upper(xmin:xmax)-ymin+1);
thisLower = single(prevUpper(xmin:xmax)-ymin+1);

% Calculate culumative sums for speed
u = fg-bg;
px = data.pairwise.xx(ymin:ymax,xmin:xmax);
py = data.pairwise.yy(ymin:ymax,xmin:xmax);
for i = 1:size(px,2)
    u(thisLower(i):end,i) = 0;
    px(thisLower(i):end,i) = 0;
end
u1 = cumsum(u, 2);
u2 = cumsum(u1(end:-1:1,:), 1);
cu = u2(end:-1:1,:);
cpy = cumsum(py, 2);
cpx = cumsum(px(end:-1:1,:),1);
cpx = cpx(end:-1:1,:);


% Start search over all rectangles
stepSize = conf.param.building.search.step;
lambda = conf.param.pairwise.lambda;
minWidth = conf.param.building.minWidth;
sxmin = min(xx-xmin+1);
sxmax = max(xx-xmin+1);
symin = min(yy-ymin)-1;

bestRect = mexOptRectangle(cu,cpy,cpx,lambda,thisUpper,thisLower,minWidth,sxmin,sxmax,symin,stepSize);
% Pick the best one
if bestRect(1) > 0,
    buildingUpper = prevUpper;
    buildingUpper(bestRect(1)+xmin:bestRect(3)+xmin-1) = bestRect(2)+ymin-1;
    rect = bestRect;
else
    buildingUpper = prevUpper;
    rect = [-1 -1 -1];
end

% Sanity check
buildingUpper = min(buildingUpper, prevUpper);