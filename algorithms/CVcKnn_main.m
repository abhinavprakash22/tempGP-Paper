function[] = CVcKnn_main(turbine)  
    if turbine == "WT1" || turbine == "WT2"
        type = "Inland";
    else 
        type = "Offshore";
    end
    
    %setting up the output file name
    outfile = strcat('./intermediate_results/',turbine,'_CVcKnn_results.txt');
    logfile = strcat("./intermediate_results/",turbine,"_CVcKnn.log");
    fprintf('%s %s\n','Executing CVc-kNN code for turbine',turbine);
    fprintf('%s %s\n\n','Results would be stored in the file:',outfile);

    data = readtable(strcat(type," Wind Farm Dataset2(",turbine,").csv"));
    yearIdx = unique(year(data.time));
    trainIndex = find(year(data.time)==yearIdx(1) | year(data.time)==yearIdx(2));
    ycol = 8;
    covariates = [2,4,5,6,7];
    cov_names = string(data.Properties.VariableNames(covariates));
    trainX = table2array(data(trainIndex,covariates)); %extracting training data
    trainY = table2array(data(trainIndex,ycol));
    options = struct('foldType',"CVc",'subsetSelection',true);

    knnObj = fitknn(trainX,trainY,options); %fitting CVc-kNN
    
    %Storing results in a text file as well for offline readability
    fId = fopen(logfile,'w');
    fprintf(fId,"Turbine: %s \n",turbine);
    fprintf(fId,"Thinning Number: %d \n",knnObj.blockSize);
    fprintf(fId,"Best subset:");
    fprintf(fId,'%s ',cov_names(knnObj.subsetId));
    fprintf(fId,'\nCVError: %.3f \n', knnObj.CVError);
    fprintf(fId,'OptimalK: %d \n', knnObj.k);
    
    %prediction for out-of-temporal datasets
    RMSEF = zeros(2,1);
    test_names = ["T2","T3"];
    for j = 1:(length(yearIdx)-2)
        testIndex = find(year(data.time)==yearIdx(j+2));
        testX = table2array(data(testIndex,covariates(knnObj.subsetId))); %extracting test data
        testY = table2array(data(testIndex,ycol));
        predF = predict(knnObj, testX);
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
