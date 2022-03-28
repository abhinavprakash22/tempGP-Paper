binning = matrix(0, nrow = 30, ncol = 2)
knn = matrix(0, nrow = 30, ncol = 2)
amk = matrix(0, nrow = 30, ncol = 2)
regGP = matrix(0, nrow = 30, ncol = 2)
tempGP = matrix(0, nrow = 30, ncol = 2)
CVcKnn = matrix(0, nrow = 30, ncol = 2)
tsKnn = matrix(0, nrow = 30, ncol = 2)
PwAmk = matrix(0, nrow = 30, ncol = 2)

for (i in 1:30){
  binning[i,] = t(read.csv(paste0('./intermediate_results/Turbine',i,'_binning_results.txt'))[,2])
  knn[i,] = t(read.csv(paste0('./intermediate_results/Turbine',i,'_knn_results.txt'))[,2])
  amk[i,] = t(read.csv(paste0('./intermediate_results/Turbine',i,'_amk_results.txt'))[,2])
  regGP[i,] = t(read.csv(paste0('./intermediate_results/Turbine',i,'_regGP_results.txt'))[,2])
  tempGP[i,] = t(read.csv(paste0('./intermediate_results/Turbine',i,'_tempGP_results.txt'))[,2])
  CVcKnn[i,] = t(read.csv(paste0('./intermediate_results/Turbine',i,'_CVcKnn_results.txt'))[,2])
  tsKnn[i,] = t(read.csv(paste0('./intermediate_results/Turbine',i,'_tsKnn_results.txt'))[,2])
  PwAmk[i,] = t(read.csv(paste0('./intermediate_results/Turbine',i,'_pw_amk_results.txt'))[,2])
}


pdf("results/Figure4a.pdf", height = 6, width = 6)
par(mai = c(1.0,1.0,0.5,0.5))
matplot(cbind(knn[,1]/binning[,1],amk[,1]/binning[,1],tempGP[,1]/binning[,1], regGP[,1]/binning[,1]), type = 'o', 
        pch = 19, lwd = 2, lty = c(4,2,1,3), col = c("blue","red","black","green"),
        xlab = "Turbine #", ylab = "relative RMSE",
        cex.lab = 1.5, cex.axis = 1.33, ylim = c(0.45,2.1))
title("a)", adj=0, cex.main=1.5)
arrows(0,1,30,1,length = 0, lwd = 2, lty = 2)
legend("topright", legend = c("kNN","AMK","tempGP","regGP"), lty = c(4,2,1,3), lwd = 3,
       col =  c("blue","red","black","green"), cex = 1.33)

dev.off()

pdf("results/Figure4c.pdf", height = 6, width = 6)
par(mai = c(1.0,1.0,0.5,0.5))
matplot(cbind(knn[,2]/binning[,2],amk[,2]/binning[,2],tempGP[,2]/binning[,2],regGP[,2]/binning[,2]), type = 'o', 
        pch = 19, lwd = 2, lty = c(4,2,1,3), col = c("blue","red","black","green"),
        xlab = "Turbine #", ylab = "relative RMSE",
        cex.lab = 1.5, cex.axis = 1.33, ylim = c(0.45,2.1))
title("c)", adj=0, cex.main=1.5)
arrows(0,1,30,1,length = 0, lwd = 2, lty = 2)
legend("topright", legend = c("kNN","AMK","tempGP","regGP"), lty = c(4,2,1,3), lwd = 3,
       col =  c("blue","red","black","green"), cex = 1.33)
dev.off()

pdf("results/Figure4b.pdf", height = 6, width = 6)
par(mai = c(1.0,1.0,0.5,0.5))
matplot(cbind(tempGP[,1]/binning[,1],tsKnn[,1]/binning[,1],CVcKnn[,1]/binning[,1],PwAmk[,1]/binning[,1]), type = 'o', 
        pch = 19, lwd = 2, lty = c(1,2,3,4), col = c("black","blue","red","green"),
        xlab = "Turbine #", ylab = "relative RMSE",
        cex.lab = 1.5, cex.axis = 1.33, ylim = c(0.45,2.1))
title("b)", adj=0, cex.main=1.5)
arrows(0,1,30,1,length = 0, lwd = 2, lty = 2)
legend("topright", legend = c("tempGP","TS-kNN","CVc-kNN","PW-AMK"), lty = c(1,2,3,4), lwd = 3,
       col =  c("black","blue","red","green"), cex = 1.2)
dev.off()

pdf("results/Figure4d.pdf", height = 6, width = 6)
par(mai = c(1.0,1.0,0.5,0.5))
matplot(cbind(tempGP[,2]/binning[,2],tsKnn[,2]/binning[,2],CVcKnn[,2]/binning[,2],PwAmk[,2]/binning[,2]), type = 'o', 
        pch = 19, lwd = 2, lty = c(1,2,3,4), col = c("black","blue","red","green"),
        xlab = "Turbine #", ylab = "relative RMSE",
        cex.lab = 1.5, cex.axis = 1.33, ylim = c(0.45,2.1))
title("d)", adj=0, cex.main=1.5)
arrows(0,1,30,1,length = 0, lwd = 2, lty = 2)
legend("topright", legend = c("tempGP","TS-kNN","CVc-kNN","PW-AMK"), lty = c(1,2,3,4), lwd = 3,
       col =  c("black","blue","red","green"), cex = 1.2)
dev.off()
