function  buildingUpper = initUpperBoundary(conf, data, lowerb, upperb, ind)
% Compute the bounds of this seed and region of interest
[h,w,~]=size(data.unary.combined);
thisSeed = data.seeds{ind};
xx = thisSeed(:,1); 
yy = thisSeed(:,2);
xmin = max(1, min(xx) - conf.param.building.maxWidth/2);
xmax = min(w, max(xx) + conf.param.building.maxWidth/2);
ymin = max(1, min(upperb(xmin:xmax))-conf.param.building.search.deltay);
ymax = min(h, max(lowerb(xmin:xmax)));

% Crop the unary and pairwise terms around the building of interest
unaryInd = ind + 1;
other = 1:size(data.unary.combined,3); 
other(other==unaryInd) = []; other(other == 1) = [];
fg = data.unary.combined(ymin:ymax,xmin:xmax,unaryInd);
bg = min(data.unary.combined(ymin:ymax,xmin:xmax,other),[],3);
thisUpper = upperb(xmin:xmax)-ymin+1;
thisLower = lowerb(xmin:xmax)-ymin+1;

% Calculate culumative sums for unaries and vertical/horizontal pairwise
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

% Search step size (hint: for speed make this larger)
stepSize = conf.param.building.search.step;

% Loop over all rectangles and pick the optimal one
rects = [];
costs = [];
lambda = conf.param.pairwise.lambda;
count = 1;
for left = (xmin:stepSize:min(xx))-xmin+1,
    for right = (max(xx):stepSize:xmax)-xmin+1, 
        if right-left < conf.param.building.minWidth 
            continue;
        end
        thisy1 = min(thisUpper(left:right));
        thisy2 = min(max(thisLower(left:right)),min(yy-ymin)-1);
        for top = thisy1:stepSize:thisy2,
                unaryCost = cu(top, right) - cu(top, left);
                pairwiseCost = cpy(top,right) - cpy(top,left) + cpx(top,left) + cpx(top,right);
                thisCost = (1-lambda)*unaryCost + lambda*pairwiseCost;
                rects(:, count) = [left; top; right];
                costs(count) = thisCost;
                count = count + 1;
        end
    end
end

% Assign all the best indices
[~, bestInd] = min(costs);
if ~isempty(bestInd)
    bestRect = rects(:,bestInd);
    buildingUpper = lowerb;
    buildingUpper(bestRect(1)+xmin:bestRect(3)+xmin-1) = bestRect(2)+ymin-1;
else
    buildingUpper = lowerb;
end
buildingUpper = min(buildingUpper, lowerb);