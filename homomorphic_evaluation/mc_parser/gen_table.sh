#!/bin/bash
echo " "
echo "Evaluation result will be saved in paper_result directory"
echo " "
echo " Name              Eval_time(s)"
echo "              before_opt     after_opt"
./he_base cardio.eqn 10 > paper_result/cardio
./he_base cardio.eqn_opted_result 8 > paper_result/cardio_opted_result
./he_base dsort.eqn 9 > paper_result/dsort
./he_base dsort.eqn_opted_result 8 > paper_result/dsort_opted_result
echo "hd01                   -             -"
echo "hd02                   -             -"
echo "hd03                   -             -"
./he_base hd04.eqn 10 > paper_result/hd04
./he_base hd04.eqn_opted_result 8 > paper_result/hd04_opted_result
echo "hd05                   -             -"
echo "hd06                   -             -"
./he_base hd07.eqn 5 > paper_result/hd07
./he_base hd07.eqn_opted_result 3 > paper_result/hd07_opted_result
./he_base hd08.eqn 6 > paper_result/hd08
./he_base hd08.eqn_opted_result 5 > paper_result/hd08_opted_result
./he_base hd09.eqn 14 > paper_result/hd09
./he_base hd09.eqn_opted_result 11 > paper_result/hd09_opted_result
./he_base hd10.eqn 6 > paper_result/hd10
./he_base hd10.eqn_opted_result 5 > paper_result/hd10_opted_result
./he_base hd11.eqn 18 > paper_result/hd11
./he_base hd11.eqn_opted_result 16 > paper_result/hd11_opted_result
./he_base hd12.eqn 16 > paper_result/hd12
./he_base hd12.eqn_opted_result 15 > paper_result/hd12_opted_result
./he_base msort.eqn 45 > paper_result/msort
./he_base msort.eqn_opted_result 36 > paper_result/msort_opted_result
./he_base isort.eqn 45 > paper_result/isort
./he_base isort.eqn_opted_result 36 > paper_result/isort_opted_result
./he_base bsort.eqn 45 > paper_result/bsort
./he_base bsort.eqn_opted_result 36 > paper_result/bsort_opted_result
./he_base osort.eqn 45 > paper_result/osort
./he_base osort.eqn_opted_result 36 > paper_result/osort_opted_result




