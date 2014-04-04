function [f,y] = sampleDetector(detector,n,buffer)
% function [f,y] = sampleDetector(detector,pres,n,buffer)
%
% Sample on and off-boundary pixels fromthe BSDS training images,
% returning 0|1 class labels in y with the associated feature 
% vectors in y.  The feature vectors are computed by the function
% provided by the argument detector.
%
% INPUT
%	detector	Function f = detector(im), where im is an
%			image and f is a mxp feature vector, where
%			m is the number of features and p is the
%			number of pixels in the image.
%	[n=1000000]	Approximate number of samples total.  Some
%			images may provide fewer samples than others.
%	[buffer=2]	Buffer zone around boundary pixels where we
%			don't take off-boundary samples.
%
% OUTPUT
%	f		Feature vectors (mxn); m=#features, n=#samples.
%	y		Vector (1xn) of 0|1 class labels (1=boundary).
%
% David R. Martin <dmartin@eecs.berkeley.edu>
% March 2003

if nargin<2, n=1000000; end
if nargin<3, buffer=2; end

% list of images
data_dir = 'Final_dataset/';
fid = fopen([data_dir 'ImageListTrain.txt']);
C = textscan(fid,'%s %s');
cityList = C{1};
iids= C{2};

% number of samples per image
nPer = ceil(n/numel(iids));

y = zeros(1,0);
f = [];

for i = 1:length(iids),
  tic;
  % read the image
  iid = iids{i};
  city = cityList{i};
  fprintf(2,'Processing image %d/%d (iid=%s)...\n',i,numel(iids),iid);
  
  im = double(imread([data_dir 'Images/' city '/' iid])) / 255;
  
  % run the detector to get feature vectors
  fprintf(2,'  Running detector...\n');
  features = feval(detector,im);
  
  % load the segmentations and union the boundary maps
  fprintf(2,'  Loading segmentations...\n');
  load([data_dir 'Annotations/' city '/label_' iid(1:end-4) '.mat'],'labels');
  if min(min(labels)) == 0
      labels = labels + 1;
  end
  writeSeg(labels,['tmp_' iid(1:end-4) '.txt']);
  segs = readSeg(['tmp_' iid(1:end-4) '.txt']);
  delete(['tmp_' iid(1:end-4) '.txt']);
  
  bmap = seg2bmap(segs);
  dmap = bwdist(bmap);
  
  % sample 
  fprintf(2,'  Sampling...\n');
  onidx = find(bmap)';
  offidx = find(dmap>buffer)';
  ind = [ onidx offidx ];
  cnt = numel(ind);
  idx = randperm(cnt);
  idx = idx(1:min(cnt,nPer));
  y = [ y bmap(ind(idx)) ];
  f = [ f features(:,ind(idx)) ];
  fprintf(2,'  %d samples.\n',numel(idx));
  toc;
end
