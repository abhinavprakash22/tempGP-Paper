function[] = regGP_ext(turbine)

    %setting up the output file name
    outfile = strcat('./intermediate_results/Turbine',num2str(turbine),'_regGP_results.txt');
    logfile = strcat('./intermediate_results/Turbine',num2str(turbine),'_regGP.log');
    fprintf('%s %d\n','Executing regGP code for Turbine',turbine);
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
    
    regGPObj = fitrgp(trainX,trainY,'KernelFunction','ardmatern32','FitMethod','exact','PredictMethod','exact'); %estimating hyperparameters using regular GP
    
    logId = fopen(logfile,'w');
    printModelSpecs(regGPObj,logId);
    
    %prediction for out-of-temporal datasets
    RMSEF = zeros(2,1);
    test_names = ["T2","T3"];
    testIndex = {};
    testIndex{1} = ((data.time_stamp > train_cutoff) &(data.time_stamp <= test_partition)); %indices for test set T_2
    testIndex{2} = (data.time_stamp > test_partition); %indices for test set T_3
    for i = 1:length(testIndex)
        testX = table2array(data(testIndex{i},covariates)); %extracting test data
        testY = table2array(data(testIndex{i},ycol));        
        predF = predict(regGPObj, testX);
        RMSEF(i) = sqrt(mean((testY- predF).^2)); %computing RMSE
        fprintf(logId,'%s %s: ','RMSE on test dataset',test_names(i)); 
        fprintf(logId,'%f\n',RMSEF(i));
    end
    fclose(logId);
    
    %Storing results in a text file for offline readability
    %open output file
    fId = fopen(outfile,'w');
    fprintf(fId,'%s,%s\n',"Data_subset","RMSE");
    fprintf(fId,'%s,%.3f\n',"Out-of-temporal T2",RMSEF(1));
    fprintf(fId,'%s,%.3f\n',"Out-of-temporal T3",RMSEF(2));
    %close output file
    fclose(fId);
end
    
function[] = printModelSpecs(regGPObj,fId)
    if nargin < 2
        fId = 1;
    end
    fprintf(fId,"%s\n","Specification of the regular GP model");
    fprintf(fId,'%s\n',"CovFn: matern32");
    fprintf(fId,"Hyperparameters: \n");
    fprintf(fId,'Theta: ');
    fprintf(fId,'%f ',regGPObj.KernelInformation.KernelParameters(1:end-1));
    fprintf(fId,'\nSigma_f: %f \n',regGPObj.KernelInformation.KernelParameters(end));
    fprintf(fId,'Sigma_n: %f \n',regGPObj.Sigma);
    fprintf(fId,'Beta: %f \n',regGPObj.Beta);
    fprintf(fId,'Objective Value: %f \n',regGPObj.LogLikelihood);
end
    