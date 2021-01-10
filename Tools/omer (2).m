 t = 0:100;
a = 0:100;
b = 0:100;
d = zeros(100,100);

for i = 1:100
    for j = 1:100
        d(i,j) = round(sqrt(a(1,i)^2+b(1,j)^2));
    end
end

d_linear = 0:141;
lamda_10 = 100/log10(100);
lamda_e = 100/log(100);
sigma0 = 100;

l0 = 0.1;

learning = zeros(1,100);
for i = 1:100
    learning(1,i) = 0.1*exp(-t(1,i)/100);
end

sigma = zeros(1,100);
for i = 1:100
    sigma(1,i) = sigma0*exp(-t(1,i)/lamda_e); %e tabanýnda
end

neighbourhood = zeros(141,101);
for i = 1:141
    for j = 1:100
        neighbourhood(i,j) = exp((-(d_linear(1,i))^2)/(2*(sigma(1,j))^2));
    end
end

lnrate = zeros(141,101);
for i = 1:141
    for j = 1:100
        lnrate(i,j) = round(neighbourhood(i,j)*learning(1,j)*1000);
    end
end


        



