binning = rep(0,30)
tempGP = rep(0,30)
tempGPJointEst = rep(0,30)

for (i in 1:30){
  binning[i] = read.csv(paste0('./intermediate_results/Turbine',i,'_binning_results.txt'))[1,2]
  tempGP[i] = read.csv(paste0('./intermediate_results/Turbine',i,'_tempGP_results.txt'))[1,2]
  tempGPJointEst[i] = read.csv(paste0('./intermediate_results/Turbine',i,'_tempGPJointEst_results.txt'))[,2]
}
relRMSE_tempGP = tempGP/binning
relRMSE_tempGPJointEst = tempGPJointEst/binning
rmseRatio = relRMSE_tempGPJointEst/relRMSE_tempGP


pdf("./results/Figure6.pdf", height = 6, width = 6)
hist(rmseRatio, main = "", xlab = "RMSE ratio", cex.lab = 1.5, cex.axis = 1.33 )
dev.off()