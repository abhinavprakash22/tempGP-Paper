################################################################################
#DESCRIPTION: sub-routines file for PW-AMK for temporal overfitting paper
################################################################################
computeThinningNumber = function(trainX){
  thinningNumber = max(apply(trainX,2,function(col) 
    min(which(c(1,abs(stats::pacf(col, plot = FALSE)$acf[,1,1])) <= (2/sqrt(nrow(trainX)))))))
  return(thinningNumber)
}

computeModifiedResponse = function(trainX, trainY, maxARorder, steps, bw = 'dpi', nMultiCov = 3, fixedCov = c(1, 2), cirCov = NA){
  modifiedY = matrix(0, nrow = length(trainY), ncol = steps)
  res = matrix(0, nrow = length(trainY), ncol = steps)
  trainpred = matrix(0, nrow = length(trainY), ncol = steps)
  rmss = rep(0,steps)
  coeffs = list()
  modY = trainY
  for (i in 1:steps){
    trainpred[,i] = DSWE::AMK(trainX, modY, trainX, bw, nMultiCov, fixedCov, cirCov)
    res[,i] = trainY - trainpred[,i]
    rmss[i] = sqrt(mean(res^2))
    fit<-arima(res[,i], order = c(maxARorder,0,0))
    coeffs[[i]] = fit$coef
    modY = trainY - (res[,i] - fit$residuals - fit$coef["intercept"])
    modifiedY[,i] = modY
  }
  return(list(modifiedY = modifiedY, rmss = rmss, maxARorder = maxARorder, trainpred = trainpred, res = res, coeffs = coeffs))
}