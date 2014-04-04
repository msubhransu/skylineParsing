function [tg] = getTexture(tmap,ntex,radius)

% David R. Martin <dmartin@eecs.berkeley.edu>
% March 2003

radius = max(1,radius);

% check texton labels
if any(tmap~=round(tmap)),
  error('texton labels not integral');
end
if min(tmap(:)) < 1 | max(tmap(:))>ntex, 
  error(sprintf('texton labels out of range [1,%d]',ntex)); 
end

% radius of discrete disc
wr = floor(radius);

% count number of pixels in a disc
[u,v] = meshgrid(-wr:wr,-wr:wr);
gamma = atan2(v,u);
mask = (u.^2 + v.^2 <= radius^2);
mask(wr+1,wr+1) = 0; % mask out center pixel to remove bias
mask = double(mask);

[h,w] = size(tmap);
tg = zeros(h*w,ntex);
for i = 1:ntex,
    im = double(tmap==i);
    tmp = conv2(im,mask,'same');
    tg(:,i) = reshape(tmp,h*w,1);
end
clear tmp;