function [mapSeg, seg, allSeg] = grabCut(im, polygon, W, pixelError, perturb, nSample, gamma, lambda)
%
% 
%
% Author: Subhransu Maji
% May 2, 2013

[ty,tx,~] = size(im);

if nargin < 3
    W = compute_weight_matrix_fast(im);
end

max_degree = max(max(W));
K = 1+max_degree;

% Get the mask from the polygon
polygon = round(polygon);
bw = roipoly(im, polygon(1,:), polygon(2,:));

% Erode the mask and let all the points inside as foreground
nhood = pixelError;
se = strel('disk',nhood,0);
srcbw = imerode(bw,se);
src = srcbw(:);

% Dilate the mask and let all the points outside as background
nhood = pixelError;
se = strel('disk',nhood,0);
dstbw = imdilate(bw,se);
dst = ~dstbw(:);

[fgData, bgData] = computeDataTerms(im, src, dst);


% MAP estimate of the figure/ground
nv = tx*ty;
T = zeros(nv,2);
T(:,2) = lambda*bgData;
T(:,1) = lambda*fgData;
K = 1+max(max(max(W)), max(T(:)));
T(src > 0,2) = K;
T(dst > 0,1) = K;
T = sparse(T);
[~,labels] = maxflow(W,T);
mapSeg = reshape(labels,[ty tx]);

if perturb
    if nargin < 6
        nSample = 20;
    end
    if nargin < 7
        gamma = 0.5;
    end
    
    if nargin < 8
        lambda = 1;
    end
    
    allSeg = zeros(ty,tx,nSample,'int32');
    fprintf('Perturb and MAP (%i samples):', nSample);
    for i = 1:nSample,
        nv = tx*ty;
        T = zeros(nv,2);
        
        % Initialize
        T(:,2) = lambda*bgData;
        T(:,1) = lambda*fgData;
        
        % Perturb
        T = T - gamma*toss('ev',nv,2);
        
        % Recompute max-edge weight
        K = 1+max(max(max(W)), max(T(:)));
        
        T(src > 0,2) = K;
        T(dst > 0,1) = K;
        T = sparse(T);

        %%run a local cut
        [~,labels] = maxflow(W,T);
        allSeg(:,:,i) = reshape(labels,[ty tx]);
        fprintf('.');
    end
    seg = mean(allSeg,3);
    fprintf('[done]\n');
end



