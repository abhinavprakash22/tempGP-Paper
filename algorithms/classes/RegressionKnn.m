classdef RegressionKnn

    properties (Access = public)
        k
        trainX
        trainY
        stdX
        stdStat
        rangeK
        foldType
        nFolds
        blockSize
        CVError
        subsetSelection 
        subsetId
    end
    
    methods (Access = public, Static = false)
        
        function obj = RegressionKnn()
            
                return
        end

        function obj = computeBestSubset(obj, bestSubset, bestError)
            if obj.foldType == "CVc"
                knn1dim = fitknn(obj.stdX(:,1),obj.trainY);
                trainpred = predict(knn1dim,obj.stdX(:,1));
                res = obj.trainY - trainpred;
                acvf = zeros(length(obj.trainY),1);
                acf = autocorr(res,'NumLags',2*obj.blockSize);
                acf = acf(2:end);
                acvf(1:length(acf)) = var(res)*acf;
            end   
            if nargin == 1
                bestSubset = [];
                bestError = Inf;
            end
            remCol = setdiff(1:size(obj.trainX,2),bestSubset);
            n_remCol = length(remCol);
            if n_remCol > 0
                bestCol = [];
                for i = 1:n_remCol
                    colSubset = [bestSubset,remCol(i)];
                    if obj.foldType == "tempFold"
                        out = RegressionKnn.computeTempFoldK(obj.stdX(:,colSubset),obj.trainY,obj.rangeK,obj.blockSize,obj.nFolds);
                    elseif obj.foldType == "randFold" 
                        out = RegressionKnn.computeRandFoldK(obj.stdX(:,colSubset),obj.trainY,obj.rangeK, obj.nFolds);
                    elseif  obj.foldType == "CVc"
                        out = RegressionKnn.computeCVcK(obj.stdX(:,colSubset),obj.trainY,obj.rangeK,obj.nFolds,acvf);
                    end
                    if out.rmse < bestError
                        bestError = out.rmse;
                        bestCol = remCol(i);
                        obj.k = out.k;
                    end
                end
                obj.CVError = bestError;
                obj.subsetId = [bestSubset,bestCol];
                if isempty(bestCol)       
                    return
                else
                    bestSubset = [bestSubset,bestCol];
                    obj = computeBestSubset(obj,bestSubset,bestError);
                end
            end
            return
        end

        function[pred] = predict(obj, testX)
            testX = utils.standardizeData(testX,obj.stdStat);
            idx = knnsearch(obj.stdX, testX, 'K', obj.k);
            pred = mean(obj.trainY(idx),2);
            return
        end
        
            
        
    end
    
     methods (Access = public, Static = true)
         
         function[out] = computeCVcK(X, y, rangeK, nFolds, acvf)
             nData = size(X,1);
             t = (1:nData)';
             foldIdx = randi(nFolds,nData,1);
             rmse = RegressionKnn.computeKnnCVc(X,y,t,rangeK, foldIdx,acvf);
             [min_rmse, kIdx] = min(rmse);
             out.k = rangeK(kIdx);
             out.rmse = sqrt(min_rmse);
         end
         
         function[rmse] = computeKnnCVc(X,y,t,rangeK,foldIdx,acvf)
             nFolds = max(foldIdx);
             rmse = zeros(nFolds,length(rangeK));
             maxK = max(rangeK);
             for fold = 1:nFolds
                 testIdx = find(foldIdx == fold);
                 trainIdx = find(foldIdx ~= fold);
                 trainY = y(trainIdx);
                 trainX = X(trainIdx,:);
                 trainT = t(trainIdx);
                 testY = y(testIdx);
                 testX = X(testIdx,:);
                 testT = t(testIdx);
                 idx = knnsearch(trainX, testX, 'K', maxK);
                 for j = 1:length(rangeK)
                     predY = mean(trainY(idx(:,1:rangeK(j))),2);
                     diffT = abs(trainT(idx(:,1:rangeK(j))) - testT);
                     diagCovY = sum((1/rangeK(j))*acvf(diffT),2);
                     rmse(fold,j) = (mean((testY - predY).^2)) + (2*mean(diagCovY));
                 end
             end
             rmse = mean(rmse);
         end
         
         function[out] = computeTempFoldK(X, y, rangeK, blockSize, nFolds)
             nData = size(X,1);
             foldIdx = RegressionKnn.assignTempFolds(nData,blockSize,nFolds);
             rmse = zeros(nFolds,length(rangeK));
             maxK = max(rangeK);
             for fold = 1:nFolds
                 testIdx = find(foldIdx == fold);
                 trainfold = setdiff(1:nFolds,mod((fold -1 - (-1:1)),nFolds)+1);
                 trainIdx = ismember(foldIdx, trainfold);
                 trainY = y(trainIdx);
                 trainX = X(trainIdx,:);
                 testY = y(testIdx);
                 testX = X(testIdx,:);
                 idx = knnsearch(trainX, testX, 'K', maxK);
                 for j = 1:length(rangeK)
                     predY = mean(trainY(idx(:,1:rangeK(j))),2);
                     rmse(fold,j) = sqrt(mean((testY - predY).^2));
                 end
             end
             rmse = mean(rmse);
             [min_rmse, kIdx] = min(rmse);
             out.k = rangeK(kIdx);
             out.rmse = min_rmse;
         end
         
         function[out] = computeRandFoldK(X, y, rangeK, nFolds)
             nData = size(X,1);
             foldIdx = randi(nFolds,nData,1);
             rmse = RegressionKnn.computeKnnCvRmse(X,y,rangeK, foldIdx);
             [min_rmse, kIdx] = min(rmse);
             out.k = rangeK(kIdx);
             out.rmse = min_rmse;
         end
         
         function[rmse] = computeKnnCvRmse(X,y,rangeK,foldIdx)
             nFolds = max(foldIdx);
             rmse = zeros(nFolds,length(rangeK));
             maxK = max(rangeK);
             for fold = 1:nFolds
                 testIdx = find(foldIdx == fold);
                 trainIdx = find(foldIdx ~= fold);
                 trainY = y(trainIdx);
                 trainX = X(trainIdx,:);
                 testY = y(testIdx);
                 testX = X(testIdx,:);
                 idx = knnsearch(trainX, testX, 'K', maxK);
                 for j = 1:length(rangeK)
                     predY = mean(trainY(idx(:,1:rangeK(j))),2);
                     rmse(fold,j) = sqrt(mean((testY - predY).^2));
                 end
             end
             rmse = mean(rmse);
             
         end
         
         function[idxFold] = assignTempFolds(nData,blockSize,nFolds)
             idxFold = zeros(nData,1);
             nBlocks = ceil(nData/blockSize);
             for i = 1:(nBlocks-1)
                 idxFold(((i-1)*blockSize)+1:(i*blockSize)) = rem(i-1,nFolds)+1;
             end
             idxFold(((nBlocks-1)*blockSize)+1:end) = rem(nBlocks-1,nFolds)+1;
         end
         
     end
         
    
end

