function  [buildingUpper, rect] = initUpperBoundary(conf, data, lowerb, upperb, ind)
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
thisUpper = single(upperb(xmin:xmax)-ymin+1);
thisLower = single(lowerb(xmin:xmax)-ymin+1);

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

% Start search over all rectangles
stepSize = conf.param.building.search.step;
lambda = conf.param.pairwise.lambda;
minWidth = conf.param.building.minWidth;
sxmin = min(xx-xmin+1);
sxmax = max(xx-xmin+1);
symin = min(yy-ymin-1);

bestRect = mexOptRectangle(cu,cpy,cpx,lambda,thisUpper,thisLower,minWidth,sxmin,sxmax,symin,stepSize);
% Pick the best one
if bestRect(1) > 0,
    buildingUpper = lowerb;
    buildingUpper(bestRect(1)+xmin:bestRect(3)+xmin-1) = bestRect(2)+ymin-1;
    rect = bestRect;
else
    buildingUpper = lowerb;
    rect = [-1 -1 -1]; % no rectangle found
end

% Sanity check
buildingUpper = min(buildingUpper, lowerb);