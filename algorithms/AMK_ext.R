################################################################################
#DESCRIPTION: estended case study file for AMK for temporal overfitting paper
################################################################################

verbose = FALSE #set this to TRUE to print detailed results.

##data path 
path = "./case_study_2/"
##setting up command args and the output file name 
args = commandArgs(trailingOnly = T)
turbine = as.integer(args[1]) #turbine = 1
outfile = paste0("./intermediate_results/Turbine",turbine,"_amk_results.txt")
logfile = paste0("./intermediate_results/Turbine",turbine,"_amk.log")
cat("Executing AMK code for Turbine",turbine,"\n")
cat("Results would be stored in the file:",outfile,'\n\n')

##reading the data and splitting into temporally disjoint train and test.
data= read.csv(paste0(path,"Turbine",turbine,".csv"))
data = data[data$outlier == 0,]
data$time_stamp=as.character(data$time_stamp)
timeformat="%Y-%m-%d %H:%M"
data$time_stamp = as.POSIXct(data$time_stamp, format = timeformat, tz="GMT")
if (turbine <= 10) {
  train_cutoff = as.POSIXct("2010-11-30", format = "%Y-%m-%d", tz="GMT")
  test_partition = as.POSIXct("2011-05-31", format = "%Y-%m-%d", tz="GMT")
  
} else if (turbine <= 20) {
  train_cutoff = as.POSIXct("2010-12-31", format = "%Y-%m-%d", tz="GMT")
  test_partition = as.POSIXct("2011-05-31", format = "%Y-%m-%d", tz="GMT")

} else {
  train_cutoff = as.POSIXct("2011-01-31", format = "%Y-%m-%d", tz="GMT")
  test_partition = as.POSIXct("2011-05-31", format = "%Y-%m-%d", tz="GMT")
}

train_index = which(data$time_stamp <= train_cutoff)
test_index = list()
test_index[[1]] = which(data$time_stamp > train_cutoff & data$time_stamp <= test_partition)
test_index[[2]] = which(data$time_stamp > test_partition)
traindata = data[train_index,]
covariate_names = colnames(data)
ycol = 8
covariates = c(3:7)
cirCov = 4
traindata = data[train_index,]

##function to create nFold CV dataset list
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
          cat("Trying covariate:",covariate_names[addCol[i]],'\n', file = logfile, append = TRUE)  
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
          predY = DSWE::AMK(trainX = trainX, trainY = trainY, testX = testX, cirCov = cirIdx, bw = 'dpi')
          rmseVec[f] = sqrt(mean((predY - testY)^2))
          if (verbose){
            cat('RMSE for fold',f,'is',rmseVec[f],'\n', file = logfile, append = TRUE) 
          }
        }
        rmse = mean(rmseVec)
        if (verbose){
          cat('Average RMSE using covariate',covariate_names[addCol[i]],'is: ',rmse,'\n', file = logfile, append = TRUE)  
        }
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
          cat("Current best subset:",covariate_names[bestSubset],'\n', file = logfile, append = TRUE)
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
bestSubsetResult = computeBestSubset(CVdataset = CVdataset, ycol = ycol, covariates = covariates, cirCov = cirCov, verbose = verbose)
bestSubset = bestSubsetResult$bestSubset
bestRMSE = bestSubsetResult$bestRMSE
if (verbose){
  cat("Average cross-validation RMSE for T1 is:",round(bestRMSE,3),'\n', file = logfile, append = TRUE)
}
cat("Best subset:",covariate_names[bestSubset],'\n', file = logfile, append = TRUE)
traindataX = as.matrix(traindata[,bestSubset])
traindataY = as.numeric(traindata[,ycol])
if (cirCov %in% bestSubset){
  cirIdx = which(bestSubset == cirCov)
} else { cirIdx = NA }
cat("Data_subset","RMSE", sep = ",", file = outfile)
cat("\n", file = outfile, append = TRUE)
test_names = c("Out-of-temporal T2","Out-of-temporal T3")
for (i in 1:2){
  testdata = data[test_index[[i]],]
  testdataX = as.matrix(testdata[,bestSubset]) 
  testdataY = as.numeric(testdata[,ycol])
  ypred = DSWE::AMK(trainX = traindataX , trainY = traindataY, testX = testdataX, cirCov = cirIdx, bw = 'dpi')
  rmse = sqrt(mean((testdataY-ypred)^2))
  if (verbose){
    cat('RMSE for AMK model for Turbine',turbine,'for test dataset',test_names[i],'is: ',rmse,'\n', file = logfile, append = TRUE) 
  }
  cat(test_names[i],round(rmse,3), sep = ",",file = outfile, append = TRUE)
  cat("\n", file = outfile, append = TRUE)
}
