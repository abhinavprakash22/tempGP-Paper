#!/bin/bash
Rscript ./algorithms/kNN_main.R Inland WT1 &
sleep 2
Rscript ./algorithms/kNN_main.R Inland WT2 &
sleep 2
Rscript ./algorithms/kNN_main.R Offshore WT3 &
sleep 2
Rscript ./algorithms/kNN_main.R Offshore WT4 &
wait