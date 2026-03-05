function t = sigTimeGenerate(data)

data = sort(data);

t(1,1) = data(1);

tmp = 0;

for i = 1:size(data,2)-1
    if data(i+1) - data(i) > 4
        tmp = tmp+1;
        t(tmp,2) = data(i);
        t(tmp+1,1) = data(i+1);
    end
end

t(tmp+1,2) = data(end);
