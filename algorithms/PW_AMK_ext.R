################################################################################
#DESCRIPTION: extended case study file for PW-AMK for temporal overfitting paper
################################################################################
source("./algorithms/PW_AMKSubroutines.R")
verbose = FALSE
##data path 
path = "./case_study_2/"

##setting up command args and the output file name 
args = commandArgs(trailingOnly = T)
turbine = as.integer(args[1])
outfile = paste0("./intermediate_results/Turbine",turbine,"_pw_amk_results.txt")
logfie = paste0("./intermediate_results/Turbine",turbine,"_pw_amk.log")
cat("Executing PW-AMK code for turbine",turbine,"\n")
cat("Results would be stored in the file:",outfile,'\n\n')
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
bestSubsetList = read.csv("./algorithms/AMK_BestSubset.txt", header = F)
bestCov = strsplit(as.character(bestSubsetList[turbine,2])," ")[[1]][-1]
bestSubset = NULL
for (i in 1:length(bestCov)){
  bestSubset = c(bestSubset,which(covariate_names==bestCov[i]))
}
cirCov = 4
traindata = data[train_index,]
traindataX = as.matrix(traindata[,bestSubset])
traindataY = as.numeric(traindata[,ycol])
if (cirCov %in% bestSubset){
  cirIdx = which(bestSubset == cirCov)
} else { cirIdx = NA }

thinningNumber = computeThinningNumber(traindataX)
steps = 1
transformedY = computeModifiedResponse(traindataX, traindataY, thinningNumber, steps, cirCov = cirIdx)
cat("Data_subset","RMSE", sep = ",", file = outfile)
cat("\n", file = outfile, append = TRUE)
test_names = c("Out-of-temporal T2","Out-of-temporal T3")
for (i in 1:2){
  testdata = data[test_index[[i]],]
  testdataX = as.matrix(testdata[,bestSubset]) 
  testdataY = as.numeric(testdata[,ycol])
  ypred = DSWE::AMK(trainX = traindataX , trainY = transformedY$modifiedY[,steps], testX = testdataX, cirCov = cirIdx, bw = 'dpi')
  rmse = sqrt(mean((testdataY-ypred)^2))
  if (verbose){
    cat('RMSE for PW-AMK model for Turbine',turbine,'for test dataset',test_names[i],'is: ',rmse,'\n', file = logfile, append = TRUE)  
  }
  cat(test_names[i],round(rmse,3), sep = ",",file = outfile, append = TRUE)
  cat("\n", file = outfile, append = TRUE)
}

