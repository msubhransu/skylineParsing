function label = parse2label(parse, data)
[h,w]  = size(data.labels);
label  = ones(h,w,'uint32');
order  = parse.order;
tiers  = parse.tiers;
tierLower = parse.lower;

tiers = [tiers; tierLower];
order = [size(tiers,1); order];

for i = 1:size(tiers,1)-1
    lowerb = order(i);
    upperb = order(i+1);
    labelb = order(i+1);
    for j = 1:w, 
        label(tiers(upperb,j):tiers(lowerb,j)-1,j) = labelb+1;
    end
end   