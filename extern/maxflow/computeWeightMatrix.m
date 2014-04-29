function W = computeWeightMatrix(I, gamma)
if(nargin < 2)
    gamma = 100;
end
if(size(I,3) > 1),
    I = rgb2gray(im2double(I));
end
[ii,jj,s] = mexComputeWeightMatrix(I, gamma);
W = sparse(double(ii),double(jj),s);   

