% Main constructor for class RegressionKnn

function[obj] = fitknn(X, y, options)

    default_options = struct();
    default_options.foldType = "randFold";
    default_options.nFolds = 5;
    default_options.subsetSelection = false;
    default_options.rangeK = 5:5:100;
    if exist('options','var')
        option_names = fieldnames(options);
        if ~ismember("foldType",option_names)
            options.foldType = default_options.foldType;
        end
        if ~ismember("nFolds",option_names)
            options.nFolds = default_options.nFolds;
        end
        if ~ismember("subsetSelection", option_names)
            options.subsetSelection = false;
        end
        if ~ismember("rangeK", option_names)
            options.rangeK = default_options.rangeK;
        end
        if options.foldType == "tempFold" || options.foldType == "CVc"   
            if ~ismember("blockSize",option_names)
                options.blockSize = utils.computeTempBlockSize(X);
            end
        end
    else

        options = default_options;
    end
    obj = RegressionKnn();
    obj.trainX = X;
    obj.trainY = y;
    [obj.stdX, obj.stdStat] = utils.standardizeData(X,"self");
    obj.rangeK = options.rangeK;
    obj.foldType = options.foldType;
    if obj.foldType == "tempFold" || options.foldType == "CVc" 
        obj.blockSize = options.blockSize;
    end
    obj.nFolds = options.nFolds;

    if options.subsetSelection == true
        obj.subsetSelection = true;
        obj = computeBestSubset(obj);
        obj.stdX = obj.stdX(:,obj.subsetId);
        obj.stdStat.location = obj.stdStat.location(obj.subsetId);
        obj.stdStat.scale = obj.stdStat.scale(obj.subsetId);
        return
    else
        obj.subsetSelection = false;
        if obj.foldType == "tempFold"
            out = RegressionKnn.computeTempFoldK(obj.stdX,obj.trainY,obj.rangeK,obj.blockSize,obj.nFolds);
        elseif obj.foldType == "randFold"
            out = RegressionKnn.computeRandFoldK(obj.stdX,obj.trainY,obj.rangeK, obj.nFolds);
        elseif  obj.foldType == "CVc"
            knn1dim = fitknn(obj.stdX(:,1),obj.trainY);
            trainpred = predict(knn1dim,obj.stdX(:,1));
            res = obj.trainY - trainpred;
            acvf = zeros(length(obj.trainY),1);
            acf = autocorr(res,'NumLags',2*obj.blockSize);
            acf = acf(2:end);
            acvf(1:length(acf)) = var(res)*acf;
            out = RegressionKnn.computeCVcK(obj.stdX,obj.trainY,obj.rangeK,obj.nFolds,acvf);
        end
        obj.CVError = out.rmse;
        obj.k = out.k;
        return
    end
end
    
        


