#!/bin/bash
echo " "
echo "Evaluation result will be saved in paper_result directory"
echo " "
echo " Name              Eval_time(s)"
echo "              before_opt     after_opt"
echo "cardio.eqn             -             -"
echo "dsort.eqn              -             -"
echo "hd01.eqn               -             -"
echo "hd02.eqn               -             -"
echo "hd03.eqn               -             -"
./he_base paper_bench/hd04.eqn 10 > paper_result/hd04
./he_base paper_bench/hd04.eqn_opted_result_baseline 9 > paper_result/hd04_opted_result_baseline
echo "hd05.eqn               -             -"
echo "hd06.eqn               -             -"
echo "hd07.eqn               -             -"
./he_base paper_bench/hd08.eqn 6 > paper_result/hd08
./he_base paper_bench/hd08.eqn_opted_result_baseline 5 > paper_result/hd08_opted_result_baseline
./he_base paper_bench/hd09.eqn 14 > paper_result/hd09
./he_base paper_bench/hd09.eqn_opted_result_baseline 12 > paper_result/hd09_opted_result_baseline
./he_base paper_bench/hd10.eqn 6 > paper_result/hd10
./he_base paper_bench/hd10.eqn_opted_result_baseline 5 > paper_result/hd10_opted_result_baseline
./he_base paper_bench/hd11.eqn 18 > paper_result/hd11
./he_base paper_bench/hd11.eqn_opted_result_baseline 17 > paper_result/hd11_opted_result_baseline
./he_base paper_bench/hd12.eqn 16 > paper_result/hd12
./he_base paper_bench/hd12.eqn_opted_result_baseline 15 > paper_result/hd12_opted_result_baseline
echo "msort.eqn              -             -"
echo "isort.eqn              -             -"
echo "bsort.eqn              -             -"
echo "osort.eqn              -             -"


