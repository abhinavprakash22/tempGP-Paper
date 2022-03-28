function[] = tempGPJointEst_ext(turbine, covType)

%setting up the output file name
outfile = strcat('./intermediate_results/Turbine',num2str(turbine),'_tempGPJointEst_results.txt');
logfile = strcat('./intermediate_results/Turbine',num2str(turbine),'_tempGPJointEst.log');
fprintf('%s %d\n','Executing joint estimation tempGP code for Turbine',turbine);
fprintf('%s %s\n\n','Results would be stored in the file:',outfile);  
data = readtable(strcat("Turbine",num2str(turbine),".csv"));
data = data(data.outlier == 0,:);
data.power(data.power < 0) = 0;
%converting circular wind direction into two regular variables using sin and cos
data.wind_direction_sin = sind(data.wind_direction); 
data.wind_direction_cos =cosd(data.wind_direction);
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
covariates = [3,5,6,7,10,11]; %input columns
trainIndex = (data.time_stamp < train_cutoff); %indices for training set T_1
trainX = table2array(data(trainIndex,covariates)); %extracting training data
trainY = table2array(data(trainIndex,ycol));
time_index = minutes( data.time_stamp - data.time_stamp(1))/10; %computing time indices
trainT = time_index(trainIndex);

if(~exist('covType','var'))
    covType = ["matern32", "matern32"];
end

if length(covType) == 1
    covType = [covType, covType];
end
output = EstimateParameters(trainY, trainX,trainT, covType); %estimating hyperparameters using tempGP

%Storing results in a text file for offline readability
fId = fopen(logfile,'w');
fprintf(fId,"Turbine: %d \n",turbine);
fprintf(fId,"CovType: ");
fprintf(fId,"%s ",covType);
fprintf(fId,"\n");
fprintf(fId,"Parameters: \n" );
fprintf(fId,"Sigma_f: %f \n",output.params.sigma_f);
fprintf(fId,"Sigma_g: %f \n",output.params.sigma_g);
fprintf(fId,"Theta: ");
fprintf(fId,"%f ",output.params.theta);
fprintf(fId,"\n");
fprintf(fId,"Phi: %f\n",output.params.phi);
fprintf(fId,"Sigma_n: %f\n",output.params.sigma_n);
fprintf(fId,"Beta: %f\n",output.params.beta);
fprintf(fId,"Objective Value: %f\n",output.fval);
fprintf(fId,"Gradient Value: ");
fprintf(fId,"%f ",output.grval);
fprintf(fId,"\n");
fprintf(fId,"Exit Flag: %d \n", output.exitflag);


testIndex = ((data.time_stamp > train_cutoff) &(data.time_stamp <= test_partition)); %indices for test set T_2
testX = table2array(data(testIndex,covariates)); %extracting test data
testY = table2array(data(testIndex,ycol));
predF = predictGPF(trainX, trainY, testX, output.params, trainT);
RMSEF = sqrt(mean((testY- predF).^2)); %computing RMSE
fprintf(fId,'%s %s: ','RMSE on test dataset T2');
fprintf(fId,'%f\n',RMSEF);
%close file
fclose(fId);

fId = fopen(outfile,'w');
fprintf(fId,'%s,%s\n',"Data_subset","RMSE");
fprintf(fId,'%s,%.3f\n',"Out-of-temporal T2",RMSEF);
fclose(fId);


end

