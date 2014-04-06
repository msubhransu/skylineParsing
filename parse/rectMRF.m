function parse = rectMRF(conf, data)
seeds = data.seeds;
numBuildings = length(seeds);
[~, w, numUnary] = size(data.unary.combined);
assert(numBuildings + 1 == numUnary);

bottom = data.region(:,2)';
upper = data.region(:,1)';

% Parse is the y coordinate of each building in each column
parse.bottom = bottom;
parse.tiers = zeros(numBuildings, w, 'uint16');
parse.order = [];
taken = false(1, numBuildings);

% Greedy labelling of all the pixels
while any(~taken), 
    ind = findBottomBuilding(bottom, seeds, taken);
    buildingUpper = upperBoundary(conf, data, bottom, upper, ind);
    bottom = min(buildingUpper, bottom);
    upper = min(bottom, upper);
    parse.tiers(ind, :) = bottom;
    taken(ind) = true;
    parse.order = [parse.order; ind];
    figure(2); clf;
    showParse(data.im, parse);
end

% Refine the rectangles using alpha expansion

function buildingUpper = upperBoundary(conf, data, bottom, upper, ind)
% Compute the bounds of this seed and region of interest
[h,w,~]=size(data.unary.combined);
thisSeed = data.seeds{ind};
xx = thisSeed(:,1); 
yy = thisSeed(:,2);
xmin = max(1, min(xx) - conf.param.building.maxWidth/2);
xmax = min(w, max(xx) + conf.param.building.maxWidth/2);
ymin = max(1, min(upper(xmin:xmax))-25);
ymax = min(h, max(bottom(xmin:xmax)));

% Crop the unary and pairwise terms around the building of interest
unaryInd = ind + 1;
other = 1:size(data.unary.combined,3); 
other(other==unaryInd) = []; other(other == 1) = [];
fg = data.unary.combined(ymin:ymax,xmin:xmax,unaryInd);
bg = min(data.unary.combined(ymin:ymax,xmin:xmax,other),[],3);
thisUpper = upper(xmin:xmax)-ymin+1;
thisBottom = bottom(xmin:xmax)-ymin+1;

% Calculate culumative sums for speed
u = fg-bg;
px = data.pairwise.xx(ymin:ymax,xmin:xmax);
py = data.pairwise.yy(ymin:ymax,xmin:xmax);
for i = 1:size(px,2)
    u(thisBottom(i):end,i) = 0;
    px(thisBottom(i):end,i) = 0;
end

u1 = cumsum(u, 2);
u2 = cumsum(u1(end:-1:1,:), 1);
cu = u2(end:-1:1,:);

cpy = cumsum(py, 2);
cpx = cumsum(px(end:-1:1,:),1);
cpx = cpx(end:-1:1,:);

stepSize = conf.param.building.step;

rects = [];
costs = [];
count = 1;
lambda = 0.1;
for left = (xmin:stepSize:min(xx))-xmin+1,
    for right = (max(xx):stepSize:xmax)-xmin+1, 
        thisy1 = min(thisUpper(left:right));
        thisy2 = min(max(thisBottom),min(yy-ymin)-1);
        for top = thisy1:stepSize:thisy2,
            rects(:,count) = [left;top;right];
            if right-left < conf.param.building.minWidth 
                costs(count) = inf;
            else
                unaryCost = cu(top, right) - cu(top, left);
                pairwiseCost = cpy(top,right) - cpy(top,left) + ...
                               cpx(top,left)  - cpx(thisBottom(left),left) + ...
                               cpx(top,right) - cpx(thisBottom(right), right);
                costs(count) = (1-lambda)*unaryCost + lambda*pairwiseCost;
            end
            count = count + 1;
        end
    end
end

[~,best] = min(costs);
if ~isempty(best),
    bestRect = rects(:,best);
    buildingUpper = bottom;
    buildingUpper(bestRect(1)+xmin:bestRect(3)+xmin-1) = bestRect(2)+ymin-1;
else
    buildingUpper = bottom;
end

%figure(1); clf;
%imagesc(u); hold on;
%plot(xx-xmin, yy-ymin,'r.');
%plot([bestRect(1) bestRect(1)], [bestRect(2) thisBottom(bestRect(1))],'k-','LineWidth',2);
%plot([bestRect(3) bestRect(3)], [bestRect(2) thisBottom(bestRect(3))],'k-','LineWidth',2);
%plot([bestRect(1) bestRect(3)], [bestRect(2) bestRect(2)], 'k-', 'LineWidth',2);
%pause;

function [ind, dmin] = findBottomBuilding(bottom, seeds, taken)
dy = zeros(length(taken), 1);
for i = 1:length(taken)
    if taken(i) 
        dy(i) = inf;
    else
        thisSeeds = seeds{i};
        xx = thisSeeds(:,1); yy = thisSeeds(:,2);
        %dy(i) = min(bottom(xx)-yy');
        dy(i) = -max(yy);
    end
end
[dmin, ind] = min(dy);

