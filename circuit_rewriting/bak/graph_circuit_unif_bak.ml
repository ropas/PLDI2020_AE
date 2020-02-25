open Circuit

module Node = struct
   type nodeVal = AND | OR | NOT | XOR | VAR of string | CONST of bool
   type label = int (* gate index(only to construct) *)
   type t = nodeVal * label
   let compare = Pervasives.compare
   let hash = Hashtbl.hash
   let equal = (=)
   (*let to_string node = 
     match node with
     | (AND, i) -> "(AND, " ^ string_of_int i ^ ")"*)
end

(* a functional/persistent graph *)
module G = Graph.Persistent.Digraph.ConcreteBidirectional(Node)

(*
let var_depth_map = ref BatMap.empty

let init_var_depth_map : G.t -> var list -> unit = fun graph -> fun vlist ->
  let current_map = !var_depth_map in
  match vlist with
  | hd::tl -> ()
  | [] -> ()
*)


let add_eqn : var list -> G.t -> eqn -> G.t = fun ilist -> fun graph -> fun eqn ->
  let (lv, bexp) = eqn in
  let root_node = (Node.VAR lv, 1) in
  let rec helper : G.t -> G.vertex -> bexp -> G.t = fun graph -> fun parent -> fun bexp ->
    match bexp with
    | NULL -> raise (Error "NULL var is used")
    | CONST b -> 
      let new_node = (Node.CONST b, 0) in
      let graph_with_node = G.add_vertex graph new_node in
      let graph_with_edge = G.add_edge graph_with_node new_node parent in
      graph_with_edge
    | VAR x -> 
      let var_index = if (List.mem x ilist) then 0 else 1 in
      let new_node = (Node.VAR x, var_index) in
      let graph_with_node = G.add_vertex graph new_node in
      let graph_with_edge = G.add_edge graph_with_node new_node parent in
      graph_with_edge
    | AND (b1, b2) ->
      let new_node = (Node.AND, G.nb_vertex graph) in
      let graph_with_node = G.add_vertex graph new_node in
      let graph_with_edge = G.add_edge graph_with_node new_node parent in
      let graph_with_b1 = helper graph_with_edge new_node b1 in
      let graph_with_b1_b2 = helper graph_with_b1 new_node b2 in
      graph_with_b1_b2
    | OR (b1, b2) ->
      let new_node = (Node.OR, G.nb_vertex graph) in
      let graph_with_node = G.add_vertex graph new_node in
      let graph_with_edge = G.add_edge graph_with_node new_node parent in
      let graph_with_b1 = helper graph_with_edge new_node b1 in
      let graph_with_b1_b2 = helper graph_with_b1 new_node b2 in
      graph_with_b1_b2
    | XOR (b1, b2) ->
      let new_node = (Node.XOR, G.nb_vertex graph) in
      let graph_with_node = G.add_vertex graph new_node in
      let graph_with_edge = G.add_edge graph_with_node new_node parent in
      let graph_with_b1 = helper graph_with_edge new_node b1 in
      let graph_with_b1_b2 = helper graph_with_b1 new_node b2 in
      graph_with_b1_b2
    | NOT b1 ->
      let new_node = (Node.NOT, G.nb_vertex graph) in
      let graph_with_node = G.add_vertex graph new_node in
      let graph_with_edge = G.add_edge graph_with_node new_node parent in
      let graph_with_b1 = helper graph_with_edge new_node b1 in
      graph_with_b1
  in
  helper graph root_node bexp

let cir2graph : circuit -> G.t = fun cir ->
  let (ilist, olist, elist) = cir in
  let empty_graph = G.empty in
  let graph_with_eqns = 
    List.fold_left
    (fun acc -> fun eqn -> 
      add_eqn ilist acc eqn) 
    empty_graph 
    elist 
  in
  graph_with_eqns

let is_valid_node : G.t -> G.vertex -> bool = fun graph -> fun node ->
  let pred_list = G.pred graph node in
  let pred_num = List.length pred_list in
  match node with
  | (Node.AND, _) | (Node.OR, _) | (Node.XOR, _) -> pred_num = 2
  | (Node.NOT, _) | (Node.VAR _, 1) -> pred_num = 1
  | (Node.VAR _, 0) -> (pred_num = 0)
  | (Node.CONST _, _) -> pred_num = 0
  | _ -> false

let rec get_bexp_of_node : G.t -> G.vertex -> bexp = fun graph -> fun node ->
  let is_valid_root = is_valid_node graph node in
  if(is_valid_root) then 
    match node with
    | (Node.CONST b, _) -> CONST b
    | (Node.VAR x, _) -> VAR x
    | (Node.AND, _) -> 
      let pred = G.pred graph node in
      let (b1_node, b2_node) = (List.nth pred 0, List.nth pred 1) in
      AND (get_bexp_of_node graph b1_node, get_bexp_of_node graph b2_node) 
    | (Node.OR, _) -> 
      let pred = G.pred graph node in
      let (b1_node, b2_node) = (List.nth pred 0, List.nth pred 1) in
      OR (get_bexp_of_node graph b1_node, get_bexp_of_node graph b2_node) 
    | (Node.XOR, _) -> 
      let pred = G.pred graph node in
      let (b1_node, b2_node) = (List.nth pred 0, List.nth pred 1) in
      XOR (get_bexp_of_node graph b1_node, get_bexp_of_node graph b2_node) 
    | (Node.NOT, _) -> 
      let pred = G.pred graph node in
      let b1_node= List.nth pred 0 in
      NOT (get_bexp_of_node graph b1_node) 
  else 
    raise (Error ("invalid node"))


let rec get_expanded_bexp_of_node : G.t -> G.vertex -> bexp = fun graph -> fun node ->
  let is_valid_root = is_valid_node graph node in
  if(is_valid_root) then 
    match node with
    | (Node.CONST b, _) -> CONST b
    | (Node.VAR x, 0) -> VAR x
    | (Node.VAR x, 1) -> 
      let pred = G.pred graph node in
      let var_node = List.nth pred 0 in
      get_expanded_bexp_of_node graph var_node
    | (Node.AND, _) -> 
      let pred = G.pred graph node in
      let (b1_node, b2_node) = (List.nth pred 0, List.nth pred 1) in
      AND (get_expanded_bexp_of_node graph b1_node, get_expanded_bexp_of_node graph b2_node) 
    | (Node.OR, _) -> 
      let pred = G.pred graph node in
      let (b1_node, b2_node) = (List.nth pred 0, List.nth pred 1) in
      OR (get_expanded_bexp_of_node graph b1_node, get_expanded_bexp_of_node graph b2_node) 
    | (Node.XOR, _) -> 
      let pred = G.pred graph node in
      let (b1_node, b2_node) = (List.nth pred 0, List.nth pred 1) in
      XOR (get_expanded_bexp_of_node graph b1_node, get_expanded_bexp_of_node graph b2_node) 
    | (Node.NOT, _) -> 
      let pred = G.pred graph node in
      let b1_node= List.nth pred 0 in
      NOT (get_expanded_bexp_of_node graph b1_node) 
    | _ -> raise (Error ("invalid node"))
  else 
    raise (Error ("invalid node"))
 


let get_bexp_of_var : G.t -> var -> bexp = fun graph -> fun var ->
  let var_node = (Node.VAR var, 1) in
  let is_valid_root = is_valid_node graph var_node in
  let pred = if(is_valid_root) then List.nth (G.pred graph var_node) 0 else raise (Error ("invalid var node : " ^ var)) in
  get_bexp_of_node graph pred  
 

let get_mult_depth_of_node : G.t -> G.vertex -> int = fun graph -> fun node ->
  let expanded_bexp = get_expanded_bexp_of_node graph node in
  get_mult_depth_expanded_bexp expanded_bexp 
  
let print_subst : (bexp, bexp) BatMap.t -> unit = fun subst ->
  let _ = print_endline("----print_subst start----") in
  let _ = BatMap.iter (fun old_bexp -> fun new_bexp -> Pp.print_bexp old_bexp; print_string("  -->  "); Pp.print_bexp new_bexp; print_newline()) subst in
  print_endline("---------------------")

let rec substitute_bexp : (bexp, bexp) BatMap.t -> bexp -> bexp = fun subst -> fun bexp ->
  match bexp with
  | NULL -> raise (Error "null is used")
  | CONST _ | VAR _ -> if (BatMap.mem bexp subst) then BatMap.find bexp subst else bexp
  | AND (b1, b2) -> 
    if (BatMap.mem bexp subst) then 
      BatMap.find bexp subst 
    else
      let subst_b1 = substitute_bexp subst b1 in
      let subst_b2 = substitute_bexp subst b2 in
      AND (subst_b1, subst_b2)
  | OR (b1, b2) -> 
    if (BatMap.mem bexp subst) then 
      BatMap.find bexp subst 
    else
      let subst_b1 = substitute_bexp subst b1 in
      let subst_b2 = substitute_bexp subst b2 in
      OR (subst_b1, subst_b2)
  | XOR (b1, b2) -> 
    if (BatMap.mem bexp subst) then 
      BatMap.find bexp subst 
    else
      let subst_b1 = substitute_bexp subst b1 in
      let subst_b2 = substitute_bexp subst b2 in
      XOR (subst_b1, subst_b2)
  | NOT b -> 
    if (BatMap.mem bexp subst) then 
      BatMap.find bexp subst 
    else
      let subst_b = substitute_bexp subst b in
      NOT subst_b


let unify : G.t -> bexp -> G.vertex -> ((bexp, bexp) BatMap.t) list = fun graph -> fun old -> fun tgt_node ->
  let empty_subst = BatMap.empty in
  let rec unify_helper : ((bexp, bexp) BatMap.t) list -> bexp -> G.vertex -> ((bexp, bexp) BatMap.t) list = 
  fun subst_list -> fun old -> fun tgt_node ->
    match (old, (fst tgt_node)) with
    | (NULL, _) -> raise (Error "null is used")
    | (CONST b1, Node.CONST b2) -> List.map (fun subst -> if (b1 = b2) then subst else BatMap.add (CONST b1) (CONST b2) subst) subst_list
    | (VAR x1, Node.VAR x2) -> List.map (fun subst -> if (x1 = x2) then subst else BatMap.add (VAR x1) (VAR x2) subst) subst_list
    | (CONST b, Node.VAR x) -> List.map (fun subst -> BatMap.add (CONST b) (VAR x) subst) subst_list
    | (VAR x, Node.CONST b) -> List.map (fun subst -> BatMap.add (VAR x) (CONST b) subst) subst_list
    | (VAR x, _) -> let tgt_bexp = get_bexp_of_node graph tgt_node in List.map (fun subst -> BatMap.add (VAR x) tgt_bexp subst) subst_list
    | (CONST x, _) -> let tgt_bexp = get_bexp_of_node graph tgt_node in List.map (fun subst -> BatMap.add (CONST x) tgt_bexp subst) subst_list
    | (_, Node.VAR x) -> 
      if (snd tgt_node = 0) then 
        List.map (fun subst -> BatMap.add old (VAR x) subst) subst_list
      else
        let pred = G.pred graph tgt_node in
        unify_helper subst_list old (List.nth pred 0)
    | (_, Node.CONST x) -> List.map (fun subst -> BatMap.add old (CONST x) subst)
    | (AND (b1, b2), Node.AND)  
    | (OR (b1, b2), Node.OR)  
    | (XOR (b1, b2), Node.XOR) -> 
      let pred = G.pred graph tgt_node in
      let tgt_b1 = List.nth pred 0 in
      let tgt_b2 = List.nth pred 1 in
      let subst_to_subst_list = fun subst ->
        let subst_with_b1_list = unify_helper subst b1 tgt_b1 in
        let subst_with_b1_b2_list = unify_helper subst_with_b1_list (substitute_bexp subst_with_b1 b2) tgt_b2 in
        let cross_subst_with_b1 = unify_helper subst b1 tgt_b2 in
	let cross_subst_with_b1_b2 = unify_helper cross_subst_with_b1 (substitute_bexp cross_subst_with_b1 b2) tgt_b1 in
        (subst_with_b1_b2::cross_subst_with_b1_b2::[])
      in
      List.concat (List.map (subst_to_subst_list) subst_list)
    | (NOT b1, Node.NOT) -> 
      let pred = G.pred graph tgt_node in
      let tgt_b1 = List.nth pred 0 in
      unify_helper subst_list b1 tgt_b1
    | _ -> let tgt_bexp = get_bexp_of_node graph tgt_node in List.map (fun subst -> BatMap.add old tgt_bexp subst) subst_list
  in
  unify_helper [empty_subst] old tgt_node

(* assume : tgt is var node *)
let graph_opt_by_case : var list -> G.t -> G.vertex -> (bexp * bexp) -> G.t = fun ilist ->  fun graph -> fun tgt_node -> fun (old_bexp, new_bexp) ->
  let subst = unify graph old_bexp tgt_node in
  (*let _ = print_subst subst in*)
  let sub_old = substitute_bexp subst old_bexp in
  let sub_old_vlist = get_bexp_varlist sub_old in
  let sub_new = substitute_bexp subst new_bexp in
  let sub_new_vlist = get_bexp_varlist sub_new in
  let is_valid_replace = (list_subset sub_old_vlist sub_new_vlist) && (list_subset sub_new_vlist sub_old_vlist) in
  if(not is_valid_replace) then
    graph
  else
    let _ = print_endline("pattern matched!") in
    let before_depth = get_mult_depth_of_node graph tgt_node in
    let pred = G.pred graph tgt_node in
    let lv = match tgt_node with | (Node.VAR x, _) -> x | _ -> raise (Error "trying to opt non-var node") in
    let _ = if(List.length pred = 1) then () else raise (Error "trying to opt non-var node") in
    let graph_without_edge = G.remove_edge graph (List.nth pred 0) tgt_node in
    let graph_with_new_tgt = add_eqn ilist graph_without_edge (lv, sub_new) in
    let after_depth = get_mult_depth_of_node graph_with_new_tgt tgt_node in
    if (after_depth <= before_depth) then graph_with_new_tgt else graph
    
  
let node_opt_by_case_list : var list -> G.t -> G.vertex -> (bexp * bexp) list -> G.t = fun ilist -> fun graph -> fun tgt_node -> fun case_list ->
  List.fold_left (fun acc -> fun case -> graph_opt_by_case ilist acc tgt_node case) graph case_list
 
let graph_opt_by_case_file : var list -> var list -> G.t -> string -> G.t = fun tgt_var_list -> fun ilist -> fun graph -> fun case_filename ->
  let input_case = open_in (case_filename) in
  let lexbuf_case = Lexing.from_channel input_case in
  let case_list = CaseParser.main CaseLexer.token lexbuf_case in
  let graph_opt_once : G.t -> G.t = fun graph ->
    List.fold_left
    (fun acc_graph -> fun tgt_var ->
      let tgt_node = (Node.VAR tgt_var, 1) in
      node_opt_by_case_list ilist acc_graph tgt_node case_list
    )
    graph
    tgt_var_list
  in
  (* TODO : 실험결과 시간 보고 fixpoint로 구현 *)
  graph_opt_once graph

let graph_depth_print : G.t -> var list -> unit = fun graph -> fun olist ->
  let _ = print_endline("---graph depth print---") in
  let rec helper : var list -> unit = fun olist ->
    match olist with
    | [] -> print_endline("---------------------")
    | hd::tl -> 
      let node = (Node.VAR hd, 1) in
      let depth = get_mult_depth_of_node graph node in
      let _ = print_endline("var : " ^ hd ^ " depth : " ^ (string_of_int depth)) in
      helper tl
  in
  helper olist

