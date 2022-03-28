#!/bin/bash  
for i in {1..10}
do
    Rscript ./algorithms/kNN_ext.R $i &
    sleep 2
done
wait
for i in {11..20}
do
    Rscript ./algorithms/kNN_ext.R $i &
    sleep 2
done
wait
for i in {21..30}
do
    Rscript ./algorithms/kNN_ext.R $i &
    sleep 2
done