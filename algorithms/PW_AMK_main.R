################################################################################
#DESCRIPTION: main case study file for PW-AMK for temporal overfitting paper
################################################################################
source("./algorithms/PW_AMKSubroutines.R")
verbose = FALSE
##data path 
path = "./case_study_1/"

##setting up command args and the output file name 
args = commandArgs(trailingOnly = T)
type = args[1] #type = "Offshore"
turbine = args[2] #turbine = "WT4"
outfile = paste0("./intermediate_results/",turbine,"_pw_amk_results.txt")
logfile = paste0("./intermediate_results/",turbine,"_pw_amk.log")
cat("Executing PW-AMK code for turbine",turbine,"\n")
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
if (turbine == "WT1" || turbine == "WT2") {
  bestSubset = c(2,6,4,5)
}else if (turbine == "WT3"){
  bestSubset = c(2,7,4,5,6)
}else {
  bestSubset = c(2,7)
}
ycol = 8
cirCov = 4
traindata = rbind(ann.data[[1]],ann.data[[2]])

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
  testdata = ann.data[[i+2]]
  testdataX = as.matrix(testdata[,bestSubset]) 
  testdataY = as.numeric(testdata[,ycol])
  ypred = DSWE::AMK(trainX = traindataX , trainY = transformedY$modifiedY[,steps], testX = testdataX, cirCov = cirIdx, bw = 'dpi')
  rmse = sqrt(mean((testdataY-ypred)^2))
  if (verbose){
    cat('RMSE using PW-AMK for Turbine',turbine,'for test dataset',test_names[i],'is: ',round(rmse,3),'\n',file = logfile, append = TRUE)
  }
  cat(test_names[i],round(rmse,3), sep = ",",file = outfile, append = TRUE)
  cat("\n", file = outfile, append = TRUE)
}


