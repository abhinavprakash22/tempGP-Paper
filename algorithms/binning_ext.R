################################################################################
#DESCRIPTION: extended case study file for binning for temporal overfitting paper
################################################################################

verbose = FALSE #set this to TRUE to print detailed results.

##data path and print configuration
path = "./case_study_2/"

##setting up command args and the output file name 
args = commandArgs(trailingOnly = T)
turbine = as.integer(args[1]) #turbine = 1
outfile = paste0("./intermediate_results/Turbine",turbine,"_binning_results.txt")
logfile = paste0("./intermediate_results/Turbine",turbine,"_binning.log")
cat("Executing binning code for Turbine",turbine,"\n")
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
ycol = 8
wscol = 3
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

## Function to predict response from IEC binning method 
binning = function(train.x, train.y, test.x, bin_width = 0.5){
  library(stats)
  train.y = as.numeric(train.y)
  train.x = as.numeric(train.x)
  test.x = as.numeric(test.x)
  start = 0
  end = round(max(train.x))
  n_bins = round((end - start)/bin_width,0)+1
  x_bin = 0
  y_bin = 0
  for (n in 2:n_bins){
    bin_element = which(train.x>(start+(n-1)*bin_width) & train.x<(start+n*bin_width))
    x_bin[n] = mean(train.x[bin_element])
    y_bin[n] = mean(train.y[bin_element])
  }
  binned_data = data.frame(x_bin, y_bin)
  binned_data = binned_data[which(is.na(binned_data$y_bin)==F),]
  splinefit = smooth.spline(x = binned_data$x_bin, y= binned_data$y_bin , all.knots = T)
  y_pred = predict(splinefit,test.x)$y
  y_pred[which(y_pred<0)] = 0
  return(y_pred) 
}


##function to compute 5 folds cross validation using binning
computeCVError = function(CVdataset, ycol, wscol, verbose = FALSE){
      rmseVec = rep(0,length(CVdataset))
      for (f in 1:length(CVdataset)){
        if (verbose){
          cat("Fold = ",f,'\n', file = logfile, append = TRUE)
        }
        trainX= as.numeric(CVdataset[[f]]$train[,wscol])
        trainY = as.numeric(CVdataset[[f]]$train[,ycol])
        testX = as.numeric(CVdataset[[f]]$test[,wscol])
        testY = as.numeric(CVdataset[[f]]$test[,ycol])
        predY = binning(train.x = trainX, train.y = trainY, test.x = testX)
        rmseVec[f] = sqrt(mean((predY - testY)^2))
        if (verbose){
          cat('RMSE for fold',f,'is',round(rmseVec[f],3),'\n', file = logfile, append = TRUE)
        }
      }
      rmse = mean(rmseVec)
      if (verbose){
        cat('Average cross-validation RMSE for T1 is: ',round(rmse,3),'\n', file = logfile, append = TRUE)  
      }
      return(rmse)
}

nFolds = 5
CVdataset = createCVdataset(traindata,nFolds)
CVErr = computeCVError(CVdataset, ycol, wscol, verbose)
traindataX = as.numeric(traindata[,wscol])
traindataY = as.numeric(traindata[,ycol])
cat("Data_subset","RMSE", sep = ",", file = outfile)
cat("\n", file = outfile, append = TRUE)
test_names = c("Out-of-temporal T2","Out-of-temporal T3")
for (i in 1:2){
  testdata = data[test_index[[i]],]
  testdataX = as.numeric(testdata[,wscol]) 
  testdataY = as.numeric(testdata[,ycol])
  ypred = binning(train.x = traindataX, train.y = traindataY, test.x = testdataX)
  rmse = sqrt(mean((testdataY-ypred)^2))
  if (verbose){
    cat('RMSE using binning for Turbine',turbine,'for test dataset',test_names[i],'is: ',round(rmse,3),'\n', file = logfile, append = TRUE)
  }
  cat(test_names[i],round(rmse,3), sep = ",",file = outfile, append = TRUE)
  cat("\n", file = outfile, append = TRUE)
}

