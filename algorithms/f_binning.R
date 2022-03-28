## Function to predict response from IEC binning method 
binning = function(train.y, train.x, bin_width, test.x){
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
  return(y_pred) 
}

binning_piecewise = function(train.y, train.x, bin_width, test.x){
  train.y = as.numeric(train.y)
  train.x = as.numeric(train.x)
  test.x = as.numeric(test.x)
  start = 0
  end = round(max(test.x))
  n_bins = round((end - start)/bin_width,0)+1
  y_pred = rep(0, length(test.x))
  for (i in 1:n_bins){
    bin_start = start + ((i-1)*bin_width)
    bin_end = bin_start + bin_width
    bin_train_idx = which(train.x >= bin_start & train.x < bin_end)
    bin_test_idx = which(test.x >= bin_start & test.x < bin_end)
    if (length(bin_train_idx) != 0 && length(bin_test_idx) != 0){
      y_pred[bin_test_idx] = mean(train.y[bin_train_idx])
    } else {
      while (length(bin_train_idx) == 0){
        bin_start = bin_start - bin_width
        bin_end = bin_end + bin_width
        bin_train_idx = which(train.x >= bin_start & train.x < bin_end)
      }
      y_pred[bin_test_idx] = mean(train.y[bin_train_idx])
    }
  }
  return(y_pred)  
}

