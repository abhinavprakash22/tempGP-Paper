function[llval, grval] = computeGPloglik(y, x, t, params1, params2)
    
    covMat = (params1.sigma_f^2)*computeCovarianceMat(x,x,params1.theta,params1.type); %covMat for F
    covMat = covMat + ((params2.sigma_g^2)*computeCovarianceMat(t,t,params2.phi,params2.type)); % covMat for G
    covMat = covMat + (eye(length(y))*(params1.sigma_n^2)); %covMat for noise
    
    cholCovMat = chol(covMat);
    clear covMat;
    diagChol = diag(cholCovMat);
    oneVec = ones(length(y),1);
    llval = ((1/2)*(y-(params1.beta*oneVec))'*(cholCovMat\(cholCovMat'\(y-(params1.beta*oneVec))))) + (sum(log(abs(diagChol)))) + (length(y)*log(2*pi)/2);
     if nargout > 1
        solOneVec = cholCovMat'\oneVec;
        solOneVec = cholCovMat\solOneVec;
        invMat = cholCovMat'\eye(length(y));
        invMat = cholCovMat\invMat;
        clear cholCovMat;
        alpha = invMat*(y-(params1.beta*oneVec));
        diffMat = (alpha*alpha') - invMat ;
        clear invMat;
        grad_size = length(params1.theta)+5;
        grval = zeros(grad_size, 1);
        if params1.type == "sqExp"
            correlMat1 = computeCovarianceMat(x,x,params1.theta,params1.type);
            commonTerm = (params1.sigma_f^2)*correlMat1;
        
        elseif params1.type == "matern32"
            distMat = sqrt(3*computeSqDistMat(x,x,params1.theta));
            commonTerm = (params1.sigma_f^2)*3*exp(-distMat);
            clear distMat;
        
        elseif params1.type == "matern52"
            distMat = sqrt(5*computeSqDistMat(x,x,params1.theta));
            commonTerm = (params1.sigma_f^2)*(5/3)*(1+distMat).*exp(-distMat);
            clear distMat;
           
        elseif params1.type == "exp"
            distMat = sqrt(computeSqDistMat(x,x,params1.theta));
            commonTerm = (params1.sigma_f^2)*exp(-distMat)./distMat;
            clear distMat;
            commonTerm(eye(size(commonTerm))==1) = 0; %setting diagonal to zero as it is independent of theta
           
        end
        for i = 1:length(params1.theta)
            delThetaMat = commonTerm.*(((x(:,i) - (x(:,i)')).^2)./(params1.theta(i)^3));
            grval(i) = (-1/2)*sum(sum(diffMat.*delThetaMat));           
        end
        clear commonTerm; 
        clear delThetaMat;
        if params1.type ~= "sqExp"
            correlMat1 = computeCovarianceMat(x,x,params1.theta,params1.type);
        end
        delSigma_fMat = (2*params1.sigma_f)*correlMat1;
        clear correlMat1;
        grval(length(params1.theta)+1) =  (-1/2)*sum(sum(diffMat.*delSigma_fMat));
        clear delSigma_fMat;
        grval(length(params1.theta)+2) = (-1/2)*trace(2*params1.sigma_n*diffMat);
        grval(length(params1.theta)+3) = (1/2)*((2*params1.beta*oneVec'*solOneVec)-(y'*solOneVec)-(oneVec'*(alpha+(params1.beta*solOneVec))));
        correlMat2 = computeCovarianceMat(t,t,params2.phi,params2.type);
        delSigma_gMat = (2*params2.sigma_g)*correlMat2;
        grval(length(params1.theta)+4) =  (-1/2)*sum(sum(diffMat.*(delSigma_gMat')));
        clear delSigma_gMat;
        if params2.type == "sqExp"        
            commonTerm = (params2.sigma_g^2)*correlMat2;
            clear correlMat2;      
            
        elseif params2.type == "matern32"
            clear correlMat2;
            distMat = sqrt(3*computeSqDistMat(t,t,params2.phi));
            commonTerm = (params2.sigma_g^2)*3*exp(-distMat);
            clear distMat;            

        elseif params2.type == "matern52"
            clear correlMat2;
            distMat = sqrt(5*computeSqDistMat(t,t,params2.phi));
            commonTerm = (params2.sigma_g^2)*(5/3)*(1+distMat).*exp(-distMat);
            clear distMat;            

        elseif params2.type == "exp"
            clear correlMat2;
            distMat = sqrt(computeSqDistMat(t,t,params2.phi));
            commonTerm = (params2.sigma_g^2)*exp(-distMat)./distMat;
            clear distMat;
            commonTerm(eye(size(commonTerm))==1) = 0; %setting diagonal to zero as it is independent of theta                  
            
        end
        delPhiMat = commonTerm.*(((t - (t')).^2)./(params2.phi^3));
        grval(length(params1.theta)+5) = (-1/2)*sum(sum(diffMat.*delPhiMat));    
        clear commonTerm; 
    end
end