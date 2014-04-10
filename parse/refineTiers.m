function buildingUpper = refineTiers(conf, data, parse, ind, label, constrainTop)

if nargin < 6
    constrainTop = false;
end

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
thisUpper = parse.upper(xmin:xmax)-ymin+1;
thisLower = prevUpper(xmin:xmax)-ymin+1;

% Calculate culumative sums for speed
u = fg-bg;
px = data.pairwise.xx(ymin:ymax,xmin:xmax);
py = data.pairwise.yy(ymin:ymax,xmin:xmax);
for i = 1:size(px,2)
    u(thisLower(i):end,i) = 0;
    px(thisLower(i):end,i) = 0;
end

seedUpper = piecewiseBound(xx-xmin+1, yy-ymin+1, size(fg,2), size(fg,1));
thisLower = min(seedUpper, double(thisLower));

if constrainTop, 
    currUpper = single(prevUpper(xmin:xmax)-ymin+1);
    currRect = parse.rect(ind, :);
    if currRect(1) > 0
        cUpper = currUpper;
        cLower = currUpper;
        cUpper(currRect(1):currRect(3)) = -1;
        cLower(currRect(1):currRect(3)) = inf;
        thisUpper = max(thisUpper, cUpper);
        thisLower = min(thisLower, cLower);
        thisUpper = min(thisLower, thisUpper);
    else
        buildingUpper = parse.tiers(ind,:);
        return;
    end
end

% Compute a rectangular upper bound from the seeds as well
u2 = cumsum(u(end:-1:1,:), 1);
cu = u2(end:-1:1,:);
cpx = cumsum(px(end:-1:1,:),1);
cpx = cpx(end:-1:1,:);

lambda = conf.param.pairwise.lambda;
tau = conf.param.building.search.tau;
[h,w] = size(u);
[dpscore, dpprev] = mexOptTiered(cu, py, cpx, lambda, single(thisUpper), single(thisLower),tau);

% Pick the best one
[~,c] = min(dpscore(:,w));
if (dpprev(c,w)) > 0,
    optPath = c;
    for i = w:-1:2, 
         c = dpprev(c, i); 
         optPath=[c optPath]; 
    end
    buildingUpper = prevUpper;
    buildingUpper(xmin:xmax) = optPath+ymin-1;
else
    buildingUpper = prevUpper;
end
buildingUpper = min(double(buildingUpper), double(prevUpper));

%figure(2); clf;
%imagesc(data.im); axis image off; hold on;
%plot(buildingUpper,'g-');
%plot(prevUpper,'b-');

function bound = piecewiseBound(x, y, w, h)
x = round(x);
y = round(y);
bound = ones(1, w)*h;
% Compute the bound at each location 
for i = 1:length(x)
    bound(x(i)) = min(bound(x(i)), y(i));
end
inds = find(bound < h);
xmin = min(x);
xmax = max(x);
if length(inds) > 1
    bound1 = interp1(inds, bound(inds), xmin:xmax,'linear');
    bound(xmin:xmax) = bound1;
end