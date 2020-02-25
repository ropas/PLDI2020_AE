#!/bin/bash
echo " "
echo "Optimization logs will be saved in paper_result directory"
echo " "
echo "  Name      Old_depth      New_depth      Opt_time(s)"
 ./main.native cardio.eqn paper_cases/leave-cardio > paper_result/cardio
 ./main.native dsort.eqn paper_cases/leave-dsort > paper_result/dsort
 ./main.native hd01.eqn paper_cases/leave-hd01 > paper_result/hd01
 ./main.native hd02.eqn paper_cases/leave-hd02 > paper_result/hd02
 ./main.native hd03.eqn paper_cases/leave-hd03 > paper_result/hd03
 ./main.native hd04.eqn paper_cases/leave-hd04 > paper_result/hd04
 ./main.native hd05.eqn paper_cases/leave-hd05 > paper_result/hd05
 ./main.native hd06.eqn paper_cases/leave-hd06 > paper_result/hd06
 ./main.native hd07.eqn paper_cases/leave-hd07 > paper_result/hd07
 ./main.native hd08.eqn paper_cases/leave-hd08 > paper_result/hd08
 ./main.native hd09.eqn paper_cases/leave-hd09 > paper_result/hd09
 ./main.native hd10.eqn paper_cases/leave-hd10 > paper_result/hd10
 ./main.native hd11.eqn paper_cases/leave-hd11 > paper_result/hd11
 ./main.native hd12.eqn paper_cases/leave-hd12 > paper_result/hd12
 ./main.native msort.eqn paper_cases/leave-msort > paper_result/msort
 ./main.native isort.eqn paper_cases/leave-isort > paper_result/isort
 ./main.native bsort.eqn paper_cases/leave-bsort > paper_result/bsort
 ./main.native osort.eqn paper_cases/leave-osort > paper_result/osort
 

