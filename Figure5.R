tempGP_thin2 = matrix(0, nrow = 30, ncol = 2)
tempGP_thin4 = matrix(0, nrow = 30, ncol = 2)
tempGP_thin8 = matrix(0, nrow = 30, ncol = 2)
tempGP_thin16 = matrix(0, nrow = 30, ncol = 2)
tempGP_thin32 = matrix(0, nrow = 30, ncol = 2)
tempGP_thin64 = matrix(0, nrow = 30, ncol = 2)
regGP = matrix(0, nrow = 30, ncol = 2)
binning = matrix(0, nrow = 30, ncol = 2)
tempGP = matrix(0, nrow = 30, ncol = 2)

for (i in 1:30){
  binning[i,] = t(read.csv(paste0('./intermediate_results/Turbine',i,'_binning_results.txt'))[,2])
  tempGP_thin2[i,] = t(read.csv(paste0('./intermediate_results/Turbine',i,'_tempGP_thin2_results.txt'))[,2])
  tempGP_thin4[i,] = t(read.csv(paste0('./intermediate_results/Turbine',i,'_tempGP_thin4_results.txt'))[,2])
  tempGP_thin8[i,] = t(read.csv(paste0('./intermediate_results/Turbine',i,'_tempGP_thin8_results.txt'))[,2])
  tempGP_thin16[i,] = t(read.csv(paste0('./intermediate_results/Turbine',i,'_tempGP_thin16_results.txt'))[,2])
  tempGP_thin32[i,] = t(read.csv(paste0('./intermediate_results/Turbine',i,'_tempGP_thin32_results.txt'))[,2])
  tempGP_thin64[i,] = t(read.csv(paste0('./intermediate_results/Turbine',i,'_tempGP_thin64_results.txt'))[,2])
  regGP[i,] = t(read.csv(paste0('./intermediate_results/Turbine',i,'_regGP_results.txt'))[,2])
  tempGP[i,] = t(read.csv(paste0('./intermediate_results/Turbine',i,'_tempGP_results.txt'))[,2])
}

pdf("results/Figure5a.pdf", height = 4, width = 6)
par(mai = c(0.85,0.85,0.25,0.25))
boxplot(cbind(regGP[,1]/binning[,1],tempGP_thin2[,1]/binning[,1],
              tempGP_thin4[,1]/binning[,1],tempGP_thin8[,1]/binning[,1],
              tempGP_thin16[,1]/binning[,1],tempGP_thin32[,1]/binning[,1],
              tempGP_thin64[,1]/binning[,1],tempGP[,1]/binning[,1]), 
        xlab = 'Thinning number (T)', ylab = "relative RMSE", xaxt='n', 
        cex.lab = 1.5, cex.axis = 1.33,
        col =c("lightgray","lightgray","lightgray","lightgray","lightgray","lightgray","lightgray","gray40"))
title('a)', adj=0, cex.main=1.5)
axis(side = 1, at= c(1:8), labels = c(2^c(0:6),"Adp"), cex.axis = 1.33)
dev.off()

pdf("results/Figure5b.pdf", height = 4, width = 6)
par(mai = c(0.85,0.85,0.25,0.25))
boxplot(cbind(regGP[,2]/binning[,2],tempGP_thin2[,2]/binning[,2],
              tempGP_thin4[,2]/binning[,2],tempGP_thin8[,2]/binning[,2],
              tempGP_thin16[,2]/binning[,2],tempGP_thin32[,2]/binning[,2],
              tempGP_thin64[,2]/binning[,2],tempGP[,2]/binning[,2]), 
        xlab = 'Thinning number (T)', ylab = "relative RMSE", xaxt='n', 
        cex.lab = 1.5, cex.axis = 1.33,
        col =c("lightgray","lightgray","lightgray","lightgray","lightgray","lightgray","lightgray","gray40"))
title('b)', adj=0, cex.main=1.5)
axis(side = 1, at= c(1:8), labels = c(2^c(0:6),"Adp"), cex.axis = 1.33)
dev.off()
