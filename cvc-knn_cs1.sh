#!/bin/bash
matlab -nodisplay -batch "addpath(genpath('./algorithms'),'./case_study_1');feature('NumThreads',4);rng(1);CVcKnn_main('WT1');CVcKnn_main('WT2');CVcKnn_main('WT3');CVcKnn_main('WT4')"