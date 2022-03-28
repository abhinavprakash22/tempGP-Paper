addpath(genpath('./algorithms'),'./case_study_1')
turbineName = ["WT1","WT2","WT3","WT4"];
thinningNumber = zeros(1,4);

for i = 1:4
     turbine = turbineName(i);
     if turbine == "WT1" || turbine == "WT2"
        type = "Inland";
    else 
        type = "Offshore";
     end
    data = readtable(strcat(type," Wind Farm Dataset2(",turbine,").csv"));
    %converting circular wind direction into two regular variables using sin and cos
    data.wind_direction_sin = sind(data.D); 
    data.wind_direction_cos =cosd(data.D);
    yearIdx = unique(year(data.time));
    trainIndex = find(year(data.time)==yearIdx(1) | year(data.time)==yearIdx(2));
    ycol = 8;
    covariates = [2,5,6,7,9,10];
    trainX = table2array(data(trainIndex,covariates)); %extracting training data
    thinningNumber(i) = utils.computeTempBlockSize(trainX);
end

fId = fopen('results/Table3.txt','w');
fprintf(fId,'%s\n',"Table 3:");
fprintf(fId,'%-16s%+5s%+5s%+5s%+5s\n',"Dataset",turbineName(1),turbineName(2),turbineName(3),turbineName(4));
fprintf(fId,'%-16s%+5s%+5s%+5s%+5s\n',"Thinning Number",num2str(thinningNumber(1)),num2str(thinningNumber(2)),num2str(thinningNumber(3)),num2str(thinningNumber(4)));
fclose(fId);
