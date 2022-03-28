turbine_name = ["WT1","WT2","WT3","WT4"];
nTurb = length(turbine_name);
tempGP = zeros(nTurb,1);
tsKnn = zeros(nTurb,1);
CVcKnn = zeros(nTurb,1);
pwAmk = zeros(nTurb,1);
knn = zeros(nTurb,1);
amk = zeros(nTurb,1);

for i = 1:nTurb 
    tempGP_result = readtable(strcat("./intermediate_results/",turbine_name(i),"_tempGP_results.txt"));
    tempGP(i) = tempGP_result.RMSE(2);
    tsKnn_result = readtable(strcat("./intermediate_results/",turbine_name(i),"_tsKnn_results.txt"));
    tsKnn(i) = tsKnn_result.RMSE(2);
    CVcKnn_result = readtable(strcat("./intermediate_results/",turbine_name(i),"_CVcKnn_results.txt"));
    CVcKnn(i) = CVcKnn_result.RMSE(2);
    pwAmk_result = readtable(strcat("./intermediate_results/",turbine_name(i),"_pw_amk_results.txt"));
    pwAmk(i) = pwAmk_result.RMSE(2);
    knn_result = readtable(strcat("./intermediate_results/",turbine_name(i),"_knn_results.txt"));
    knn(i) = knn_result.RMSE(2);
    amk_result = readtable(strcat("./intermediate_results/",turbine_name(i),"_amk_results.txt"));
    amk(i) = amk_result.RMSE(2);
end
fId = fopen('results/Table7.txt','w');
fprintf(fId,'%s\n',"Table 7 Results:");
fprintf(fId,'%-8s%+8s%+8s%+8s%+8s%+8s%+8s\n','Dataset','tempGP','TS-kNN','CVc-kNN','PW-AMK','kNN','AMK');
fprintf(fId,'---------------------------------------------------------\n');
for i = 1:nTurb
    fprintf(fId,'%-8s%8.2f%8.2f%8.2f%8.2f%8.2f%8.2f\n',turbine_name(i),tempGP(i),tsKnn(i),CVcKnn(i),pwAmk(i),knn(i),amk(i));
    fprintf(fId,'---------------------------------------------------------\n');
end
fclose(fId);
