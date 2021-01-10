
t = 0:100;
a = 0:300;
b = 0:300;
d = zeros(301,301);

for i = 1:301
    for j = 1:301
        d(i,j) = sqrt(a(1,i)^2+b(1,j)^2);
    end
end

d_linear = 0:424;

lamda_10 = 100/log10(300);
lamda_e = 100/log(300);
sigma0 = 300;

l0 = 0.1;

learning = zeros(1,101);
for i = 1:101
    learning(1,i) = exp(-t(1,i)/100);
end

sigma = zeros(1,101);
for i = 1:101
    sigma(1,i) = sigma0*exp(-t(1,i)/lamda_e); %e tabanýnda
end

neighbourhood = zeros(425,101);
for i = 1:425
    for j = 1:101
        neighbourhood(i,j) = exp((-(d_linear(1,i))^2)/(2*(sigma(1,j))^2));
    end
end

lnrate = zeros(425,101);
for i = 1:425
    for j = 1:101
        lnrate(i,j) = neighbourhood(i,j)*learning(1,j)*1000;
    end
end


        



