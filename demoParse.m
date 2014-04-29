%% Get data for a given image
conf = skylineConfig();
anno = loadAnno();
dataId = 36; 
data = getData(conf, anno, dataId);
gtLabels = data.gtLabels;
fprintf('Loaded data for id=%i\n', dataId);

%% Prepare data (unary potentials)
data = prepareData(conf, data);
    
%% Get parses using rectangle/refined MRF
rparse = skylineParse(conf, data, 'rectangle');

%% Get parses using rectangle/refined MRF
tparse = skylineParse(conf, data, 'tiered');

%% Display parses
figure;

% Image and ground truth
vl_tightsubplot(2,4,1,'Margin',0.01);
imagesc(data.im); axis image off;
title('image','fontSize',16);

vl_tightsubplot(2,4,5,'Margin',0.01);
imagesc(gtLabels); axis image off;
title('ground-truth','fontSize',16);

% Rectangle MRF
vl_tightsubplot(2,4,2,'Margin',0.01);
showParse(data.im, rparse.rect);
evals = evalLabels(parse2label(rparse.rect, data), gtLabels);
title('rectangle MRF','fontSize',16);

vl_tightsubplot(2,4,6,'Margin',0.01);
imagesc(parse2label(rparse.rect, data)); axis image off;
title(sprintf('MAO=%.2f', evals.mao*100),'fontSize',16);

% refined MRF
vl_tightsubplot(2,4,3,'Margin',0.01);
showParse(data.im, rparse.refined);
evals = evalLabels(parse2label(rparse.refined, data), gtLabels);
title('refined MRF','fontSize',16);

vl_tightsubplot(2,4,7,'Margin',0.01);
imagesc(parse2label(rparse.refined, data)); axis image off;
title(sprintf('MAO=%.2f', evals.mao*100),'fontSize',16);

% tiered MRF
vl_tightsubplot(2,4,4,'Margin',0.01);
showParse(data.im, tparse.tiered);
evals = evalLabels(parse2label(tparse.tiered, data), gtLabels);
title('tiered MRF','fontSize',16);

vl_tightsubplot(2,4,8,'Margin',0.01);
imagesc(parse2label(tparse.tiered, data)); axis image off;
title(sprintf('MAO=%.2f', evals.mao*100),'fontSize',16);



