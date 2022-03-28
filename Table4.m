turbine_name = ["WT1","WT2","WT3","WT4"];
nTurb = length(turbine_name);
binning = zeros(nTurb,1);
knn = zeros(nTurb,1);
amk = zeros(nTurb,1);
tempGP = zeros(nTurb,1);

for i = 1:nTurb 
    binning_result = readtable(strcat("./intermediate_results/",turbine_name(i),"_binning_results.txt"));
    binning(i) = binning_result.RMSE(1);
    knn_result = readtable(strcat("./intermediate_results/",turbine_name(i),"_knn_results.txt"));
    knn(i) = knn_result.RMSE(1);
    amk_result = readtable(strcat("./intermediate_results/",turbine_name(i),"_amk_results.txt"));
    amk(i) = amk_result.RMSE(1);
    tempGP_result = readtable(strcat("./intermediate_results/",turbine_name(i),"_tempGP_results.txt"));
    tempGP(i) = tempGP_result.RMSE(1);
end
fId = fopen('results/Table4.txt','w');
fprintf(fId,'%s\n',"Table 4 Results:");
fprintf(fId,'%-8s%+8s%+8s%+8s%+8s\n','Dataset','binning','kNN','AMK','tempGP');
fprintf(fId,'-----------------------------------------\n');
for i = 1:nTurb
    fprintf(fId,'%-8s%8.2f%8.2f%8.2f%8.2f\n',turbine_name(i),binning(i),knn(i),amk(i),tempGP(i));
    fprintf(fId,'-----------------------------------------\n');
end
fclose(fId);
