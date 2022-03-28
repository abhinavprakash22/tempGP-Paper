################################################################################
#DESCRIPTION: file for binning based power curve plot
################################################################################
source('algorithms/f_binning.R')
data = read.csv('case_study_1/Inland Wind Farm Dataset2(WT1).csv')
set.seed(1)
data = data[sample(nrow(data),1000),]

bin_width = 0.5
test.x = seq(0,22,0.01)
pred = binning(data$normPW, data$V,bin_width,test.x)
pred[pred<0] = 0
pred[pred>100] = 100
pred_piecewise = binning_piecewise(data$normPW, data$V,bin_width,test.x)
pdf('results/Figure1.pdf', height = 6, width = 8)
plot(data$V,data$normPW, pch = 19,xaxs = "i", yaxs = "i", col = 'red', xlab = 'Wind speed, V (m/s) ', ylab = 'Normalized power, y', cex.axis = 1.5, cex.lab = 1.5, cex = 0.75, xlim = c(0,20))
rated_ws = 13
points(test.x,pred, type = 'l', lwd = 4)
points(test.x, pred_piecewise, 'col'='blue', cex = 0.5, pch = 19)
arrows(rated_ws,0,rated_ws,100, code =0, lty = 2)
arrows(0,100,rated_ws,100, code =0, lty = 2)
dev.off()
