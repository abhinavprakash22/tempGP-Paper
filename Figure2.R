################################################################################
#DESCRIPTION: file for temporal overfitting demonstration plot
################################################################################
set.seed(1)
x = seq(0,1,length.out = 100)
f = 5*(x**2)


#Autocorrelated errors
Cov = matrix(NA,100,100)
for (i in 1:100){
  for (j in 1:100){
    Cov[i,j] = 0.4*exp(-(abs((x[i]-x[j]))/0.05)) 
  }
}
diag(Cov) = diag(Cov) + 0.1
cholCov = chol(Cov)
error_autocorr = t(cholCov)%*%rnorm(100)
y1 = f + error_autocorr

pdf("results/Figure2.pdf", height = 6, width = 16)
par(mfrow=c(1,2))
par(mai = c(1.0,1.0,0.5,1.0))
plot(x,f,type = 'l', lwd =3, xlab = "X", ylab = "Y", cex.lab = 1.5, cex.axis = 1.5, main = "a) Correlated errors", cex.main = 1.5)
points(x,y1, pch = 19, cex = 0.5)
pred1 = DSWE::AMK(trainX = as.matrix(x), testX = as.matrix(x), trainY = y1, nMultiCov = 1, fixedCov = 1)
points(x,pred1, type = 'l', col = 'red', lwd = 4, lty = 2)
legend("topleft", legend = c("True Function", "Estimated Function"),  lty = c(1,2), lwd = c(2,3), col = c("black","red"), cex = 1.5)

#IID errors
error_iid = rnorm(100,0,0.5)
y2 = f + error_iid
par(mai = c(1.0,1.5,0.5,0.5))
plot(x,f,type = 'l', lwd =3, xlab = "X", ylab = "Y", cex.lab = 1.5, cex.axis = 1.5, main = "b) Independent errors", cex.main = 1.5)
points(x,y2, pch = 19, cex = 0.5)
pred2 = DSWE::AMK(trainX = as.matrix(x), testX = as.matrix(x), trainY = y2, nMultiCov = 1, fixedCov = 1)
points(x,pred2, type = 'l', col = 'red', lwd = 4, lty = 2)
legend("topleft", legend = c("True Function", "Estimated Function"),  lty = c(1,2), lwd = c(2,3), col = c("black","red"), cex = 1.5)
dev.off()

