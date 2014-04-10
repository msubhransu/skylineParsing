function label=trimLabels(label, data)
w = size(data.region,1);
for i = 1:w,
    label(1:data.region(i,1),i) = 1;
    label(data.region(i,2):end,i) = 1;
end