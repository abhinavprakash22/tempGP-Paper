#!/bin/bash

Rscript Figure1.R
echo "Figure 1 generated and stored inside the results folder."
sleep 2

Rscript Figure2.R
echo "Figure 2 generated and stored inside the results folder."
sleep 2  

Rscript Figure4.R
echo "Figure 4 generated and stored inside the results folder."
sleep 2

Rscript Figure5.R
echo "Figure 5 generated and stored inside the results folder."
sleep 2  


matlab -nodisplay -batch "Table3; Table4; Table5; Table6; Table7; exit"
echo "Tables are generated and stored inside the results folder."