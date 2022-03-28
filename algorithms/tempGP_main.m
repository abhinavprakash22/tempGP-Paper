function[] = tempGP_main(turbine,varargin)
    defaultCov = "matern32";
    expectedCovs = {'sqExp','matern32','matern52','exp'};
    parser = inputParser;
    addRequired(parser,'turbine');
    addOptional(parser,'thinNum',[]);
    addParameter(parser,'covFn',defaultCov,@(x) any(validatestring(x,expectedCovs)));
    parse(parser,turbine,varargin{:});
    thinNum = parser.Results.thinNum;
    covFn = parser.Results.covFn;
    if turbine == "WT1" || turbine == "WT2"
        type = "Inland";
    else 
        type = "Offshore";
    end
    
    %setting up the output file name
    if ~isempty(thinNum) && covFn == defaultCov
        outfile = strcat('./intermediate_results/',turbine,'_tempGP_thin',num2str(thinNum),'_results.txt');
        logfile = strcat('./intermediate_results/',turbine,'_tempGP_thin',num2str(thinNum),'.log');
    elseif ~isempty(thinNum) && covFn ~= defaultCov
        outfile = strcat('./intermediate_results/',turbine,'_tempGP_',covFn,'_thin',num2str(thinNum),'_results.txt');
        logfile = strcat('./intermediate_results/',turbine,'_tempGP_',covFn,'_thin',num2str(thinNum),'.log');
    elseif isempty(thinNum) && covFn ~= defaultCov
        outfile = strcat('./intermediate_results/',turbine,'_tempGP_',covFn,'_results.txt');
        logfile = strcat('./intermediate_results/',turbine,'_tempGP_',covFn,'.log');
    elseif isempty(thinNum) && covFn == defaultCov
        outfile = strcat('./intermediate_results/',turbine,'_tempGP_results.txt');
        logfile = strcat('./intermediate_results/',turbine,'_tempGP.log');
    end
    fprintf('%s %s\n','Executing tempGP code for turbine',turbine);
    fprintf('%s %s\n\n','Results would be stored in the file:',outfile);
    
    %reading data
    data = readtable(strcat(type," Wind Farm Dataset2(",turbine,").csv"));

    %converting circular wind direction into two regular variables using sin and cos
    data.wind_direction_sin = sind(data.D); 
    data.wind_direction_cos =cosd(data.D);
    
    yearIdx = unique(year(data.time));
    trainIndex = find(year(data.time)==yearIdx(1) | year(data.time)==yearIdx(2));
    ycol = 8;
    covariates = [2,5,6,7,9,10];
    trainX = table2array(data(trainIndex,covariates)); %extracting training data
    trainY = table2array(data(trainIndex,ycol));

    if ~isempty(thinNum) 
        options = struct('thinningNumber',thinNum,'covFn',covFn);   
    else 
       options = struct('covFn',covFn);
    end
    tempGPObj = fitTempGP(trainX,trainY,options); %estimating hyperparameters using tempGP

    %Storing params in a text file for offline readability
    fId = fopen(logfile,'w');
    fprintf(fId,"Turbine: %s \n",turbine);
    printModelSpecs(tempGPObj,fId);  
    
    %prediction for out-of-temporal datasets
    RMSEF = zeros(2,1);
    test_names = ["T2","T3"];
    for j = 1:(length(yearIdx)-2)
        testIndex = find(year(data.time)==yearIdx(j+2));
        testX = table2array(data(testIndex,covariates)); %extracting test data
        testY = table2array(data(testIndex,ycol));
        [predF, tempGPObj] = predict(tempGPObj, testX);
        RMSEF(j) = sqrt(mean((testY- predF).^2)); %computing RMSE
        fprintf(fId,'%s %s: ','RMSE on test dataset',test_names(j)); 
        fprintf(fId,'%f\n',RMSEF(j));
    end
    fclose(fId);
    fId = fopen(outfile,'w');
    fprintf(fId,'%s,%s\n',"Data_subset","RMSE");
    fprintf(fId,'%s,%.3f\n',"Out-of-temporal T2",RMSEF(1));
    fprintf(fId,'%s,%.3f\n',"Out-of-temporal T3",RMSEF(2));
    fclose(fId);
end
