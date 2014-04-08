function buildingUpper = refineTiers(conf, data, parse, ind, label)
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
minVal = min(u(:));
for i = 1:length(xx), 
    u(yy(i)-ymin+1:end, xx(i)-xmin+1) = -1e6;
end

px = data.pairwise.xx(ymin:ymax,xmin:xmax);
py = data.pairwise.yy(ymin:ymax,xmin:xmax);
for i = 1:size(px,2)
    u(thisLower(i):end,i) = 0;
    px(thisLower(i):end,i) = 0;
end
u2 = cumsum(u(end:-1:1,:), 1);
cu = u2(end:-1:1,:);
cpx = cumsum(px(end:-1:1,:),1);
cpx = cpx(end:-1:1,:);

lambda = conf.param.pairwise.lambda;
[h,w] = size(u);
dptable = inf(h,w, 'single');
dpprev = zeros(h, w, 'single');
for i = 1:w,
    for j = thisUpper(i):thisLower(i),
        if i == 1,
            dptable(j,i) = lambda*cu(j,i) + (1-lambda)*(py(j,i) + cpx(j,i));
        else
            tmp = inf(1, h);
            for k = thisUpper(i-1):thisLower(i-1),
                tmp(k) = dptable(k,i-1) + lambda*cu(j,i) + (1-lambda)*(py(j,i) + abs(cpx(j,i) - cpx(k,i)));
            end
            [minVal, minInd] = min(tmp);
            dpprev(j,i) = minInd;
            dptable(j,i) = minVal;
        end
    end
end

% Pick the best one
[~,ind] = min(dptable(:,w));
if ~isinf(dptable(ind,w)),
    path = ind;
    for i = w:-1:2, 
         ind = dpprev(ind, i); 
         path=[ind path]; 
    end
    buildingUpper = prevUpper;
    buildingUpper(xmin + (1:w)-1) = path+ymin;
else
    buildingUpper = prevUpper;
end
buildingUpper = min(buildingUpper, prevUpper);
%figure(1); clf;
%imagesc(data.im(ymin:ymax, xmin:xmax,:)); 
%axis image off;
%hold on; 
%plot(1:length(prevSoln), prevSoln,'k-', 'LineWidth',2);
%plot(1:length(prevSoln), buildingUpper(xmin:xmax)-ymin+1,'r-','LineWidth',2);
%plot(1:length(prevSoln), thisLower,'b-','LineWidth',2);

%keyboard;
%imagesc(data.im); axis image; hold on;
%plot(1:w, buildingUpper,'g-');
%plot(1:w, prevUpper,'r-');