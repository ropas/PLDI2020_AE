(*
 * boolean eqn to ocamlgraph
 *)

open Graph_circuit
open Unify
open Graph_opt

exception Error of string
let filename = Sys.argv.(1)
let case_filename = Sys.argv.(2)

(*let _ = Sys.command("mkdir ./z3_tmpdir/" ^ filename)*)

let start_time = Unix.time()

let eqn2circuit : string -> Circuit.circuit = fun filename ->
  let input_eqn = open_in (filename) in
  let lexbuf = Lexing.from_channel input_eqn in
  let circuit = EqnParser.main EqnLexer.token lexbuf in
  circuit

let tgt_cir = eqn2circuit filename
let tgt_graph = cir2graph tgt_cir
let _ = print_endline("cir to graph finished")


let (ilist, olist, elist) = tgt_cir
let vlist_to_print = (List.map fst elist)
(*
let _ =
  List.map
    (fun v -> print_string(v ^ " is valid : "); print_endline (string_of_bool (is_valid_node tgt_graph (Node.VAR v, 1))))
    vlist_to_print
*)

let _ = print_endline("old graph depth")
let _ = graph_depth_print tgt_graph olist

let tgt_vlist = List.map fst elist
let new_graph = graph_opt_by_case_file tgt_graph filename case_filename

let _ = print_endline("graph opt finished")
let _ = Eqn_printer.print_graph new_graph

let _ = print_endline("new graph depth")
let _ = graph_depth_print new_graph olist

let old_depth = graph_max_depth tgt_graph olist
let _ = print_endline("old mult depth : " ^ (string_of_int old_depth))
let new_depth = graph_max_depth new_graph olist
let _ = print_endline("new mult depth : " ^ (string_of_int new_depth))
let consumed_time = string_of_int (int_of_float(Unix.time() -. start_time))


let filename = let regexp = Str.regexp_string "paper_bench/" in Str.global_replace regexp "" filename 
let filename_length = String.length filename
let time_length = String.length consumed_time
let old_depth_string = if (old_depth < 10) then " " ^ (string_of_int old_depth) else (string_of_int old_depth)
let new_depth_string = if (new_depth < 10) then " " ^ (string_of_int new_depth) else (string_of_int new_depth)

let rec empty_n_string n = if(n = 0) then "" else " " ^ empty_n_string (n-1) 

let _ = prerr_endline("             " ^ (new_depth_string) ^ empty_n_string (17 - time_length) ^  consumed_time)

(* graph print test *) 

(*let _ =
  List.map
    (fun v -> print_string(v ^ " is valid : "); print_endline (string_of_bool (is_valid_node new_graph (Node.VAR v, 1))))
    vlist_to_print
*)

