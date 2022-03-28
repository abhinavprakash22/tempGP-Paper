#!/bin/bash
matlab -nodisplay -batch "addpath(genpath('./algorithms'),'./case_study_1');feature('NumThreads',12);tempGP_main('WT4')"