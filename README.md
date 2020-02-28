# Lobster
Lobster : Homomorphic Evaluation Circuit Optimizer by Program Synthesis and Term Rewriting

## Requirements
*	flex 2.6.4
*	bison 3.0.4
*	Opam 2.0.4(with Ocaml 4.10.0)
	*	ocamlfind 1.8.1
	*	ocamlbuild 0.14.0
	*	ocamlgraph 1.8.8
	*	batteries 3.0.0
*	cmake 3.10.2

```sh
sudo apt-get install opam cmake flex bison
opam init
eval `opam config env`
opam install ocamlfind ocamlgraph batteries
```

## Build (tested on Linux)
```sh
$ ./build.sh
```

## Benchmarks and Datas
*	circuit\_rewriting/paper\_bench : Benchmarks from Cingulata, Hackers Delight, Sorting Algorithm (Table 1)
*	circuit\_rewriting/paper\_cases/all\_cases : Machind-found Aggresive Optimization Patterns by Offline-Learning (Section 4.2)
*	circuit\_rewriting/paper\_cases/leave... : Optimization patterns for leave-one-out Cross Validation (Section 5.2)
*	homomorphic\_evaluation/mc\_parser/paper\_bench : Original/Opted benchmarks by Lobster and Carpov.et.al

## Reproducing the experimental results in the paper
```sh
# Run the experiments
$ ./artifact [string | bitvec | circuit] [--timeout <sec> (default: 3600)] [--memory <GB> (default: 16)]
# Table 4,5,6
$ ./artifact [string | bitvec | circuit] --timeout 3600
# Table 4,5,6 without EUSOLVER
$ ./artifact [string | bitvec | circuit] --timeout 3600 --only_euphony
# Figure 8
$ ./artifact [string | bitvec | circuit] --timeout 3600 --only_euphony --strategy [pcfg | uniform | pcfg_uniform]
```

## Run Euphony on a single SyGus file
```sh
$ ./bin/run_[string | bitvec | circuit] [a SyGuS input file]
# For example
$ ./bin/run_string benchmarks/string/test/exceljet1.sl
```



