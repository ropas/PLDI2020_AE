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

## Data description
*	circuit\_rewriting/paper\_bench : Benchmarks from Cingulata, Hackers Delight, Sorting Algorithm (Table 1)
*	circuit\_rewriting/paper\_cases/all\_cases : Machind-found aggresive optimization patterns by offline-learning (Section 4.2)
*	circuit\_rewriting/paper\_cases/leave... : Optimization patterns for leave-one-out cross validation (Section 5.2)
*	homomorphic\_evaluation/mc\_parser/paper\_bench : Original/Opted benchmarks by Lobster and Carpov.et.al

## Reproducing the experimental results in the paper
```sh
# Table 2, depth optimization results
$ ./gen_table_rewriting.sh
# Table 2, homomorphic evaluation time results(evaluate circuits optimized by Lobster)
$ ./gen_table_eval.sh
# Table 2, homomorphic evaluation time results(evaluate circuits optimized by Carpov.et.al)
$ ./gen_table_eval_baseline.sh
```

## Optimize single homomorphic circuit
```sh
# Lobster
$ cd circuit_rewriting
$ ./main.native [ input circuit file(*.eqn) ] [ optimization patterns file(paper_cases/*) ]
# Carpov.et.al
$ cd baseline
$ ./main.native [ input circuit file(*.eqn) ] baseline_cases
```


## Evaluate single homomorphic circuit
```sh
$ cd homomorphic_evaluation/mc_parser
$ ./he_base [ input circuit file(*.eqn) ] [ multiplicative depth ]
```



