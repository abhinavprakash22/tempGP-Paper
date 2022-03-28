#!/bin/bash
Rscript ./algorithms/AMK_main.R Inland WT1 &
sleep 2
Rscript ./algorithms/AMK_main.R Inland WT2 & 
sleep 2
Rscript ./algorithms/AMK_main.R Offshore WT3 &
sleep 2
Rscript ./algorithms/AMK_main.R Offshore WT4 &
wait
