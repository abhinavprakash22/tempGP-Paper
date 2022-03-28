#!/bin/bash
matlab -nodisplay -batch "addpath(genpath('./algorithms'),'./case_study_2');feature('NumThreads',4);for i = 1:30;CVcKnn_ext(i);end"