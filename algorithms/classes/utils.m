%% A class for utility methods

classdef utils

    methods (Static)

        function rmse = computeRmse(a,b)
            rmse = sqrt(mean((a-b).^2));
            return
        end
        
        function[stdData, stdStat] = standardizeData(data, ref, excludeCols)
            ref = convertCharsToStrings(ref);
            if isstring(ref)
                if ref == "self"
                    location = mean(data);
                    scale = std(data);
                end   
            else
                location = ref.location;
                scale = ref.scale;
            end
            if nargin > 2
                location(excludeCols) = 0;
                scale(excludeCols) = 1;
            end 
            stdData = zeros(size(data));
            for i = 1:size(stdData,2)
                stdData(:,i) = (data(:,i) - location(i))/scale(i);
            end
            if nargout > 1
                stdStat.location = location;
                stdStat.scale = scale;
            end
        end

        function blockSize = computeTempBlockSize(X)
            nData = size(X,1);
            nCov = size(X,2);
            lag_bound = 2/sqrt(nData);
            blockSize = 1;
            for i = 1:nCov
                nLag = 80;
                covBlockSize = find(abs(parcorr(X(:,i),'NumLags',nLag))<= lag_bound, 1);
                if isempty(covBlockSize)
                    while isempty(covBlockSize) && nLag < nData
                        nLag = min(2*nLag,nData);
                        covBlockSize = find(abs(parcorr(X(:,i),'NumLags',nLag))<= lag_bound, 1);
                    end
                    if isempty(covBlockSize)
                        error("Serial autocorrelation larger than data size. Cannot compute temporal block size. Not suitable for block validation.")
                    end
                end
                blockSize = max(blockSize,covBlockSize);
            end
                return
        end

        function grad = computeGradient(obj,x,delta)
            fval = obj(x);
            grad = zeros(size(x));
            for i = 1:length(grad)
               epsilon = zeros(size(x));
               epsilon(i) = delta;
               grad(i) = (obj(x+epsilon) - fval)/delta;
            end
            return
       end
        
    end
end