function[] = CVcKnn_ext(turbine)
%setting up the output file name
outfile = strcat('./intermediate_results/Turbine',num2str(turbine),'_CVcKnn_results.txt');
logfile = strcat('./intermediate_results/Turbine',num2str(turbine),'_CVcKnn.log');
fprintf('%s %s\n','Executing CVc-kNN code for Turbine',num2str(turbine));
fprintf('%s %s\n\n','Results would be stored in the file:',outfile);


data = readtable(strcat("Turbine",num2str(turbine),".csv")); %read the data
data = data(data.outlier == 0,:);
if turbine <= 10
    train_cutoff = datetime(2010,11,30);
    test_partition = datetime(2011,05,31);
elseif turbine <= 20
    train_cutoff = datetime(2010,12,31);
    test_partition = datetime(2011,05,31);
else
    train_cutoff = datetime(2011,01,31);
    test_partition = datetime(2011,05,31);
end
ycol = 8; %output column
covariates = 3:7; %input columns
cov_names = string(data.Properties.VariableNames(covariates));
trainIndex = (data.time_stamp < train_cutoff); %indices for training set T_1
trainX = table2array(data(trainIndex,covariates)); %extracting training data
trainY = table2array(data(trainIndex,ycol));
options = struct('foldType',"CVc",'subsetSelection',true);

knnObj = fitknn(trainX,trainY,options); %fitting temporal kNN

%Storing results in a text file as well for offline readability
fId = fopen(logfile,'w');
fprintf(fId,"Turbine: %d \n",turbine);
fprintf(fId,"Thinning Number: %d \n",knnObj.blockSize);
fprintf(fId,"Best subset:");
fprintf(fId,'%s ',cov_names(knnObj.subsetId));
fprintf(fId,'\nCVError: %.3f \n', knnObj.CVError);
fprintf(fId,'OptimalK: %d \n', knnObj.k);

%prediction for out-of-temporal datasets
RMSEF = zeros(2,1);
test_names = ["T2","T3"];
testIndex = {};
testIndex{1} = ((data.time_stamp > train_cutoff) &(data.time_stamp <= test_partition)); %indices for test set T_2
testIndex{2} = (data.time_stamp > test_partition); %indices for test set T_3
for i = 1:length(testIndex)
    testX = table2array(data(testIndex{i},covariates(knnObj.subsetId))); %extracting test data
    testY = table2array(data(testIndex{i},ycol));
    predF = predict(knnObj, testX);
    RMSEF(i) = sqrt(mean((testY- predF).^2)); %computing RMSE
    fprintf(fId,'%s %s: ','RMSE on test dataset',test_names(i));
    fprintf(fId,'%f\n',RMSEF(i));
end
%close log file
fclose(fId);
%open output file
fId = fopen(outfile,'w');
fprintf(fId,'%s,%s\n',"Data_subset","RMSE");
fprintf(fId,'%s,%.3f\n',"Out-of-temporal T2",RMSEF(1));
fprintf(fId,'%s,%.3f\n',"Out-of-temporal T3",RMSEF(2));
%close output file
fclose(fId);
end
