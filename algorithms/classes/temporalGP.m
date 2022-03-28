classdef temporalGP < utils
    properties (Access = public)
        trainX
        trainY
        standardize
        stdX
        stdStat
        params
        thinningNumber
        thinnedData
        loss
        weightedY
    end
    
    methods (Access = public, Static = false)
        
        function obj = temporalGP(X,y,standardize,params)
                
            obj.trainX = X;
            obj.trainY = y;
            if nargin > 2
                if standardize
                    obj.standardize = true;
                    [obj.stdX, obj.stdStat] = utils.standardizeData(obj.trainX,"self");
                end
                if nargin > 3
                    obj.params = params;
                end
            end      
            
            return
            
        end
       
        function obj = estimateHyperparameters(obj)
            
            if isempty(obj.thinningNumber)
                obj.thinningNumber = utils.computeTempBlockSize(obj.trainX);
            end

            if isempty(obj.thinnedData)
                obj = computeThinnedData(obj);
            end

            ncov = size(obj.trainX,2);
           
            bindata = obj.thinnedData;
           
            beta = mean(obj.trainY);
            sigma_f = std(obj.trainY)/sqrt(2);
            sigma_n = sigma_f;  
            if obj.standardize 
                theta = std(obj.stdX);
            else
                theta = std(obj.trainX);
            end
            par0 = [theta, sigma_f, sigma_n, beta];
            objectiveFn = @(par)computeGPloglikSum(bindata,ncov+1, 1:ncov,struct('theta',par(1:ncov),'sigma_f',par(ncov+1),'sigma_n',par(ncov+2),'beta',par(ncov+3),'type',obj.params.type));
            options = optimoptions('fminunc','Display','none','SpecifyObjectiveGradient',true);
            [sol, fval, exitflag] =  fminunc(objectiveFn,par0,options);
            obj.params.theta = abs(sol(1:ncov));
            obj.params.sigma_f = abs(sol(ncov+1));
            obj.params.sigma_n = abs(sol(ncov+2));
            obj.params.beta = sol(ncov+3);
            obj.loss.name = "loglikelihood";
            obj.loss.val = -fval;
            [~, gradval] = computeGPloglikSum(bindata,ncov+1, 1:ncov, obj.params);
            obj.loss.exitflag = exitflag;
            obj.loss.gradient = gradval;
            return
        end

        function obj = computeThinnedData(obj)
            if obj.standardize
                data = [obj.stdX,obj.trainY];
            else
                data = [obj.trainX,obj.trainY];
            end
            nData = size(data,1);    
            obj.thinnedData = cell(obj.thinningNumber,1);
            for i = 1:obj.thinningNumber
                nPoints = floor((nData - i)/obj.thinningNumber);
                lastIdx = i + (nPoints*obj.thinningNumber);
                idx = linspace(i,lastIdx,nPoints+1); 
                obj.thinnedData{i} = data(idx,:);
            end
            return
        end

        function [pred, obj] = predict(obj,testX)
            if obj.standardize
                X = obj.stdX;
                testX = utils.standardizeData(testX,obj.stdStat);
            else
                X = obj.trainX;
            end
            Y = obj.trainY;
            theta = obj.params.theta;
            beta = obj.params.beta;
            sigma_f = obj.params.sigma_f;
            sigma_n = obj.params.sigma_n;
            if isempty(obj.weightedY)
                trainCovMat = (sigma_f^2)*computeCovarianceMat(X, X, theta, obj.params.type);
                trainCovMat = trainCovMat + ((sigma_n^2)*eye(size(X,1)));
                opts.POSDEF = true;
                opts.SYM = true; 
                obj.weightedY = linsolve(trainCovMat,Y-beta,opts);
                clear trainCovMat
            end 
            testCovMat = (sigma_f^2)*computeCovarianceMat(testX,X,theta,obj.params.type);
            pred = beta + (testCovMat*obj.weightedY);
            return
        end

        function [predInt, credInt] = computePredictionInterval(obj, testX, varargin)
            parser = inputParser;
            addRequired(parser, 'obj');
            addRequired(parser, 'testX');
            addOptional(parser, 'confLevel', 0.95);
            parse(parser,obj, testX, varargin{:});
            confLevel = parser.Results.confLevel;
            if obj.standardize
                X = obj.stdX;
                testX = utils.standardizeData(testX,obj.stdStat);
            else
                X = obj.trainX;
            end
            theta = obj.params.theta;
            sigma_f = obj.params.sigma_f;
            sigma_n = obj.params.sigma_n;
            trainCovMat = (sigma_f^2)*computeCovarianceMat(X, X, theta, obj.params.type);
            trainCovMat = trainCovMat + ((sigma_n^2)*eye(size(X,1)));
            testCovMat = (sigma_f^2)*computeCovarianceMat(X,testX,theta,obj.params.type);
            opts.POSDEF = true;
            opts.SYM = true; 
            Kinv_testCov = linsolve(trainCovMat,testCovMat,opts);
            credVar = sigma_f^2 - (sum(testCovMat.*Kinv_testCov)');
            credInt = norminv([(1-confLevel)/2, (1+confLevel)/2]).*sqrt(credVar);
            predInt = norminv([(1-confLevel)/2, (1+confLevel)/2]).*sqrt(credVar+(sigma_n^2));
            return
        end

        function[predg] = computeLocalFunction(obj, trainT, testT)
            residual = obj.trainY - predict(obj,obj.trainX);
            predg = zeros(length(testT),1); 
            for i = 1: length(predg) 
                tDist = abs(trainT - testT(i));
                proximalIdx = find(tDist <= obj.thinningNumber);
                if (~isempty(proximalIdx))
                    gpMdl = fitrgp(trainT(proximalIdx),residual(proximalIdx),'BasisFunction','none');
                    predg(i) = predict(gpMdl,testT(i));
                else
                    predg(i) = 0;
                end
            end
        end

        function [] = printModelSpecs(obj, fId)
            if nargin < 2
                fId = 1;
            end
            fprintf(fId,"%s\n","Specification of the temporal GP model");
            fprintf(fId,"Thinning Number: %d \n",obj.thinningNumber);
            fprintf(fId,"Covariance function: %s \n",obj.params.type);
            fprintf(fId,"Hyperparameters: \n");
            fprintf(fId,'Theta: ');
            fprintf(fId,'%f ',obj.params.theta);
            fprintf(fId,'\nSigma_f: %f \n',obj.params.sigma_f);
            fprintf(fId,'Sigma_n: %f \n',obj.params.sigma_n);
            fprintf(fId,'Beta: %f \n',obj.params.beta);
            fprintf(fId,'Objective Value: %f \n',obj.loss.val);
            fprintf(fId,'Gradient Vector: ');
            fprintf(fId,'%f ',obj.loss.gradient);
            fprintf(fId,'\nExit Flag: %d \n', obj.loss.exitflag);
        end
    
    end

    methods (Access = public, Static = true)
        function params = getHyperparametersFromFile(filename)
            params = struct();
            fId = fopen(filename, 'r');
            while ~feof(fId)
                tline = fgetl(fId);
                if startsWith(tline, "Covariance function")
                    params.type = split(tline, ' ');
                    params.type = string(params.type(3));
                elseif startsWith(tline, "Theta")
                    params.theta = split(tline,  ' ');
                    params.theta = params.theta(2:end);
                    params.theta = str2double(params.theta(strlength(params.theta) > 0));
                elseif startsWith(tline, "Sigma_f")
                    params.sigma_f = split(tline,  ' ');
                    params.sigma_f = params.sigma_f(2);
                    params.sigma_f = str2double(params.sigma_f(strlength(params.sigma_f) > 0));
                elseif startsWith(tline, "Sigma_n")
                    params.sigma_n = split(tline,  ' ');
                    params.sigma_n = params.sigma_n(2);
                    params.sigma_n = str2double(params.sigma_n(strlength(params.sigma_n) > 0));
                elseif startsWith(tline, "Beta")
                    params.beta = split(tline,  ' ');
                    params.beta = params.beta(2); 
                    params.beta = str2double(params.beta(strlength(params.beta) > 0));
                end
            end

            return
        end
    end

end

function[distMat] = computeSqDistMat(x1,x2,theta)
    nrows = size(x1,1);
    ncols = size(x2,1);
    ncov = size(x1,2);
    distMat = zeros(nrows,ncols);
    if nargin > 2
        if ncov > 1
            for i = 1:ncov
                distMat = distMat + (((x1(:,i) - (x2(:,i)')).^2)/(theta(i)^2));
            end
        else
            distMat =  ((x1 - (x2')).^2)/(theta^2);
        end
    elseif nargin == 2
        if ncov > 1
            for i = 1:ncov
                distMat = distMat + ((x1(:,i) - (x2(:,i)')).^2);
            end
        else
            distMat =  ((x1 - (x2')).^2);
        end
    else
        error('function requires at least two inputs.\n')
    end
end

function[covMat] = computeCovarianceMat(x1,x2, theta, type)
    distMat = computeSqDistMat(x1, x2, theta);
    if type == "sqExp"
        covMat = exp(-0.5*distMat);
    elseif type == "matern32"
        covMat = (1+sqrt(3*distMat)).*exp(-sqrt(3*distMat));
    elseif type == "matern52"
        covMat = (1+sqrt(5*distMat)+(5*distMat/3)).*exp(-sqrt(5*distMat));
    elseif type == "exp"
        covMat = exp(-sqrt(distMat));
    end
      
    return

end

function[llval, grval] = computeGPloglik(y, x, params)
    correlMat = computeCovarianceMat(x,x,params.theta,params.type);
    covMat = ((params.sigma_f^2)*correlMat) + (eye(length(y))*(params.sigma_n^2));
    cholCovMat = chol(covMat);
    clear covMat;
    diagChol = diag(cholCovMat);
    oneVec = ones(length(y),1);
    llval = ((1/2)*(y-(params.beta*oneVec))'*(cholCovMat\(cholCovMat'\(y-(params.beta*oneVec))))) + (sum(log(abs(diagChol)))) + (length(y)*log(2*pi)/2);
    if nargout > 1
        solOneVec = cholCovMat\(cholCovMat'\oneVec);
        invMat = cholCovMat\(cholCovMat'\eye(length(y)));
        clear cholCovMat;
        alpha = invMat*(y-(params.beta*oneVec));
        diffMat = (alpha*alpha') - invMat ;
        clear invMat;
        grad_size = length(params.theta)+3;
        grval = zeros(grad_size, 1);
        if params.type == "sqExp"
            for i = 1:length(params.theta)
                delThetaMat = (params.sigma_f^2)*((((x(:,i) - (x(:,i)')).^2)./(params.theta(i)^3)).*correlMat);
                grval(i) = (-1/2)*sum(sum(diffMat.*delThetaMat));            
            end
        elseif params.type == "matern32"
            distMat = sqrt(3*computeSqDistMat(x,x,params.theta));
            commonTerm = (params.sigma_f^2)*3*exp(-distMat);
            clear distMat;
            for i = 1:length(params.theta)
                delThetaMat = commonTerm.*(((x(:,i) - (x(:,i)')).^2)./(params.theta(i)^3));
                grval(i) = (-1/2)*sum(sum(diffMat.*delThetaMat));            
            end
            clear commonTerm;
        elseif params.type == "matern52"
            distMat = sqrt(5*computeSqDistMat(x,x,params.theta));
            commonTerm = (params.sigma_f^2)*(5/3)*(1+distMat).*exp(-distMat);
            clear distMat;
            for i = 1:length(params.theta)
                delThetaMat = commonTerm.*(((x(:,i) - (x(:,i)')).^2)./(params.theta(i)^3));
                grval(i) = (-1/2)*sum(sum(diffMat.*delThetaMat));            
            end
            clear commonTerm;
        elseif params.type == "exp"
            distMat = sqrt(computeSqDistMat(x,x,params.theta));
            commonTerm = (params.sigma_f^2)*exp(-distMat)./distMat;
            clear distMat;
            commonTerm(eye(size(commonTerm))==1) = 0; %setting diagonal to zero as it is independent of theta
            for i = 1:length(params.theta)
                delThetaMat = commonTerm.*(((x(:,i) - (x(:,i)')).^2)./(params.theta(i)^3));
                grval(i) = (-1/2)*sum(sum(diffMat.*delThetaMat));           
            end
            clear commonTerm; 
        end
        clear delThetaMat;
        delSigma_fMat = (2*params.sigma_f)*correlMat;
        clear correlMat;
        grval(length(params.theta)+1) =  (-1/2)*sum(sum(diffMat.*delSigma_fMat));
        clear delSigma_fMat;
        grval(length(params.theta)+2) = (-1/2)*trace(2*params.sigma_n*diffMat);
        grval(length(params.theta)+3) = (1/2)*((2*params.beta*oneVec'*solOneVec)-(y'*solOneVec)-(oneVec'*(alpha+(params.beta*solOneVec))));
        clear cholCovMat alpha oneVec;
    end
end

function [llfsum, gradsum] = computeGPloglikSum(bindata,ycol, covariates,params)
    n_bins = length(bindata);
    binllf = zeros(n_bins,1); 
    if nargout > 1
        grad_size = length(params.theta)+3;
        gr = zeros(grad_size, n_bins);
        for i = 1:n_bins
            data = bindata{i};            
            x = data(:,covariates);
            y = data(:,ycol);
            [binllf(i), gr(:,i)] = computeGPloglik(y,x,params);
        end
        llfsum = sum(binllf);
        gradsum = sum(gr,2);
        
    else
     for i = 1:n_bins
            data = bindata{i};            
            x = data(:,covariates);
            y = data(:,ycol);
            binllf(i) = computeGPloglik(y,x,params);
     end
     llfsum = sum(binllf);   
    end   
 end