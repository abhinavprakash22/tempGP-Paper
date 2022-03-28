function[pred] = predictGPF(trainX, trainY, testX, params, trainT )
    theta = params.theta;
    phi = params.phi;
    beta = params.beta;
    sigma_f = params.sigma_f;
    sigma_g = params.sigma_g;
    sigma_n = params.sigma_n;
    covTypeF = params.type(1);
    covTypeG = params.type(2);
    trainCovMat = (sigma_f^2)*computeCovarianceMat(trainX, trainX, theta, covTypeF);
    trainCovMat = trainCovMat + ((sigma_g^2)*computeCovarianceMat(trainT, trainT, phi, covTypeG));
    trainCovMat = trainCovMat + ((sigma_n^2)*eye(size(trainX,1)));
    opts.POSDEF = true;
    opts.SYM = true; 
    linSys = linsolve(trainCovMat,trainY-beta,opts);
    clear trainCovMat 
    testCovMat = (sigma_f^2)*computeCovarianceMat(testX,trainX,theta, covTypeF);
    pred = beta + (testCovMat*linSys);
end