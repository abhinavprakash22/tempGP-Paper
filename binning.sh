#!/bin/sh

#shell script for running binning code for case study 1
Rscript ./algorithms/binning_main.R Inland WT1
Rscript ./algorithms/binning_main.R Inland WT2
Rscript ./algorithms/binning_main.R Offshore WT3
Rscript ./algorithms/binning_main.R Offshore WT4

#shell script for running binning code for case study 2
for i in {1..30}
do
Rscript ./algorithms/binning_ext.R $i
done