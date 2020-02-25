#!/bin/bash

#for eqn in ./sorting_bench/*.eqn
for eqn in ./$1/*.eqn
do
    echo 'target circuit : '$eqn
    time ./main.native $eqn ./case_list/cross_validation/all_cases > ./term_result/$eqn.result
    echo ''
    echo ''
done

