function showParse(im, parse)
imagesc(im); axis image off; hold on;

[~,w,~] = size(im);

plot(1:w, parse.tiers(parse.order(end),:),'g-','LineWidth',2);
for i = length(parse.order)-1:-1:1 
    plot(1:w, parse.tiers(parse.order(i),:),'r-','LineWidth',2);
end
plot(1:w, parse.bottom,'r-','LineWidth',2);
    