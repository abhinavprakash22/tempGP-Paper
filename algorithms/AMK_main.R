################################################################################
#DESCRIPTION: main case study file for AMK for temporal overfitting paper
################################################################################

verbose = FALSE #set this to TRUE to print detailed results.

##data path 
path = "./case_study_1/"

##setting up command args and the output file name 
args = commandArgs(trailingOnly = T)
type = args[1] #type = "Inland"
turbine = args[2] #turbine = "WT1"
outfile = paste0("./intermediate_results/",turbine,"_amk_results.txt")
logfile = paste0("./intermediate_results/",turbine,"_amk.log")
cat("Executing AMK code for turbine",turbine,"\n")
cat("Results would be stored in the file:",outfile,'\n\n')

##reading the data and splitting into temporally disjoint train and test.
data= read.csv(paste0(path,type," Wind Farm Dataset2(",turbine,").csv"))
data$time=as.character(data$time)
timeformat="%Y-%m-%d %H:%M:%S"
data$time = as.POSIXct(data$time, format = timeformat, tz="GMT")
timeindex = as.integer(difftime(data$time,data$time[1], units = "mins"))/10
data = cbind(data, timeindex)
yrs=as.factor(format((data$time),format="%Y"))
ann.data=split(data,yrs)
covariates = c(2,4,5,6,7)
ycol = 8
cirCov = 4
traindata = rbind(ann.data[[1]],ann.data[[2]])
covariate_names = colnames(data)

##function to create nFold CV dataset list; to be used for in-temporal predictions
createCVdataset = function(dataset, nFolds){
  set.seed(1)
  cv_sample = sample(nrow(dataset))
  folds = cut(seq(1:length(cv_sample)),breaks = nFolds, labels = F)
  CVdataset = vector("list", nFolds)
  for (f in 1:nFolds){
    testindex = cv_sample[which(folds == f,arr.ind = T)]
    CVdataset[[f]]$train = dataset[-testindex,]
    CVdataset[[f]]$test = dataset[testindex,]
  }
  return(CVdataset)
}


##Subset Selection as well as in-temporal average RMSE.
computeBestSubset = function(CVdataset, ycol, covariates, cirCov, bestSubset = NULL, bestRMSE = Inf, verbose = FALSE){
    addCol = setdiff(covariates, bestSubset)
    ncov = length(addCol)
    if (ncov>0){
      bestCol = NULL
      for (i in 1:ncov){
        if (verbose){
          cat("Trying covariate:",addCol[i],'\n', file = logfile, append = TRUE)  
        }
        
        rmseVec = rep(0,length(CVdataset))
        covSubset = c(bestSubset,addCol[i])
        for (f in 1:length(CVdataset)){
          if (verbose){
            cat("Fold = ",f,'\n', file = logfile, append = TRUE)  
          }
          
          trainX = as.matrix(CVdataset[[f]]$train[,covSubset])
          trainY = as.numeric(CVdataset[[f]]$train[,ycol])
          testX = as.matrix(CVdataset[[f]]$test[,covSubset])
          testY = as.numeric(CVdataset[[f]]$test[,ycol])
          if (addCol[i] == cirCov){
            cirIdx = which(covSubset == cirCov)
          } else {cirIdx = NA}
          if (length(covSubset) <= 3){
            nMultiCov = "all"
          } else {nMultiCov = 3}
          predY = DSWE::AMK(trainX = trainX, trainY = trainY, testX = testX, cirCov = cirIdx, nMultiCov = nMultiCov, bw = 'dpi' )
          rmseVec[f] = sqrt(mean((predY - testY)^2))
          if (verbose){
            cat('RMSE for fold',f,'is',rmseVec[f],'\n', file = logfile, append = TRUE)
          }
          
        }
        rmse = mean(rmseVec)
        if (rmse < bestRMSE){
          bestRMSE = rmse
          bestCol = addCol[i]
        }
      }
      if (length(bestCol)==0){
        retList = list(bestRMSE = bestRMSE, bestSubset = bestSubset)
      } else {
        bestSubset = c(bestSubset,bestCol)
        if (verbose){
          cat("Current best subset:",bestSubset,'\n', file = logfile, append = TRUE)
          cat("Current best RMSE:",round(bestRMSE,3),'\n', file = logfile, append = TRUE)  
        }
        retList = computeBestSubset(CVdataset, ycol, covariates, cirCov, bestSubset, bestRMSE)
      }
    } else {
      retList = list(bestRMSE = bestRMSE, bestSubset = bestSubset)
    }
    return(retList)
}

nFolds = 5
CVdataset = createCVdataset(traindata,nFolds)
bestSubsetResult = computeBestSubset(CVdataset = CVdataset, ycol = ycol, covariates = covariates, cirCov = cirCov, bestSubset = 2, verbose = verbose)
bestSubset = bestSubsetResult$bestSubset
bestRMSE = bestSubsetResult$bestRMSE
if (verbose){
  cat("Average cross-validation RMSE for T1 is:",round(bestRMSE,3),'\n', file = logfile, append = TRUE)
}
cat("Best subset:",covariate_names[bestSubset],'\n', file = logfile, append = TRUE)
cat("Data_subset","RMSE", sep = ",", file = outfile)
cat("\n", file = outfile, append = TRUE)
traindataX = as.matrix(traindata[,bestSubset])
traindataY = as.numeric(traindata[,ycol])
test_names = c("Out-of-temporal T2","Out-of-temporal T3")
if (cirCov %in% bestSubset){
  cirIdx = which(bestSubset == cirCov)
} else { cirIdx = NA }
if (length(bestSubset) == 2){
  nMultiCov = 2
} else {nMultiCov = 3}
for (i in 1:2){
  testdata = ann.data[[i+2]]
  testdataX = as.matrix(testdata[,bestSubset]) 
  testdataY = as.numeric(testdata[,ycol])
  ypred = DSWE::AMK(trainX = traindataX , trainY = traindataY, testX = testdataX, cirCov = cirIdx, nMultiCov = nMultiCov, bw = 'dpi')
  rmse = sqrt(mean((testdataY-ypred)^2))
  if (verbose){
    cat('RMSE using AMK for',turbine,'for test dataset',test_names[i],'is: ',round(rmse,3),'\n', file = logfile, append = TRUE)
  }
  cat(test_names[i],round(rmse,3), sep = ",",file = outfile, append = TRUE)
  cat("\n", file = outfile, append = TRUE)
}
cat("In-temporal T1",round(bestRMSE,3), sep = ",", file = outfile, append = TRUE)
cat("\n", file = outfile, append = TRUE)