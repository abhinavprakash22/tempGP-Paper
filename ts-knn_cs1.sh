#!/bin/bash
matlab -nodisplay -batch "addpath(genpath('./algorithms'),'./case_study_1');feature('NumThreads',4);rng(1);tsKnn_main('WT1');tsKnn_main('WT2');tsKnn_main('WT3');tsKnn_main('WT4')"