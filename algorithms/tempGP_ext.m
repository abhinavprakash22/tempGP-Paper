function[] = tempGP_ext(turbine,varargin)
defaultCov = "matern32";
expectedCovs = {'sqExp','matern32','matern52','exp'};
parser = inputParser;
addRequired(parser,'turbine');
addOptional(parser,'thinNum',[]);
addParameter(parser,'covFn',defaultCov,@(x) any(validatestring(x,expectedCovs)));
parse(parser,turbine,varargin{:});
thinNum = parser.Results.thinNum;
covFn = parser.Results.covFn;
%setting up the output file name
if ~isempty(thinNum) && covFn == defaultCov
    outfile = strcat('./intermediate_results/Turbine',num2str(turbine),'_tempGP_thin',num2str(thinNum),'_results.txt');
    logfile = strcat('./intermediate_results/Turbine',num2str(turbine),'_tempGP_thin',num2str(thinNum),'.log');
elseif ~isempty(thinNum) && covFn ~= defaultCov
    outfile = strcat('./intermediate_results/Turbine',num2str(turbine),'_tempGP_',covFn,'_thin',num2str(thinNum),'_results.txt');
    logfile = strcat('./intermediate_results/Turbine',num2str(turbine),'_tempGP_',covFn,'_thin',num2str(thinNum),'.log');
elseif isempty(thinNum) && covFn ~= defaultCov
    outfile = strcat('./intermediate_results/Turbine',num2str(turbine),'_tempGP_',covFn,'_results.txt');
    logfile = strcat('./intermediate_results/Turbine',num2str(turbine),'_tempGP_',covFn,'.log');
elseif isempty(thinNum) && covFn == defaultCov
    outfile = strcat('./intermediate_results/Turbine',num2str(turbine),'_tempGP_results.txt');
    logfile = strcat('./intermediate_results/Turbine',num2str(turbine),'_tempGP.log');
end
fprintf('%s %d\n','Executing tempGP code for Turbine',turbine);
fprintf('%s %s\n\n','Results would be stored in the file:',outfile);

data = readtable(strcat("Turbine",num2str(turbine),".csv"));
data = data(data.outlier == 0,:);
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

if ~isempty(thinNum) 
    options = struct('thinningNumber',thinNum,'covFn',covFn);   
else 
   options = struct('covFn',covFn);
end
tempGPObj = fitTempGP(trainX,trainY,options); %estimating hyperparameters using tempGP
%Storing results in a text file for offline readability
fId = fopen(logfile,'w');
fprintf(fId,"Turbine: %d \n",turbine);
printModelSpecs(tempGPObj,fId);

%prediction for out-of-temporal datasets
RMSEF = zeros(2,1);
test_names = ["T2","T3"];
testIndex = {};
testIndex{1} = ((data.time_stamp > train_cutoff) &(data.time_stamp <= test_partition)); %indices for test set T_2
testIndex{2} = (data.time_stamp > test_partition); %indices for test set T_3
for i = 1:length(testIndex)
    testX = table2array(data(testIndex{i},covariates)); %extracting test data
    testY = table2array(data(testIndex{i},ycol));
    [predF, tempGPObj] = predict(tempGPObj, testX);
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
