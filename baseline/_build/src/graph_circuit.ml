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

let print_node : G.vertex -> unit = fun node ->
  let _ = print_string("nodeVal : ") in
  let _ =
    match fst node with
    | Node.AND -> print_string("AND")
    | Node.OR -> print_string("OR")
    | Node.XOR -> print_string("XOR")
    | Node.NOT -> print_string("NOT")
    | Node.VAR x -> print_string x
    | Node.CONST b -> print_string (string_of_bool b)
  in
  let _ = print_string (" index : " ^ string_of_int (snd node)) in
  ()
(*
let print_subst : (bexp * bexp) list -> unit = fun subst ->
  let _ = print_endline("----print_subst start----") in
  let _ = List.map (fun (old_bexp, new_bexp) -> Pp.print_bexp old_bexp; print_string("  -->  "); Pp.print_bexp new_bexp; print_newline()) subst in
  print_endline("---------------------")
*)

let print_subst : (var, bexp) BatMap.t -> unit = fun subst ->
  let _ = print_endline("----print_subst start----") in
  let _ = BatMap.iter (fun var -> fun new_bexp -> print_string("var " ^ var ^ "  -->  "); Pp.print_bexp new_bexp; print_newline()) subst in
  print_endline("---------------------")


let rec is_equal_bexp : bexp -> bexp -> bool = fun b1 -> fun b2 ->
  match (b1, b2) with
  | (NULL, _) | (_, NULL) -> raise (Error "null used")
  | (CONST b1, CONST b2) -> (b1 = b2)
  | (VAR v1, VAR v2) -> (v1 = v2)
  | (AND (a, b), AND(c, d)) 
  | (XOR (a, b), XOR(c, d)) 
  | (OR (a, b), OR(c, d)) -> ((is_equal_bexp a c) && (is_equal_bexp b d)) || ((is_equal_bexp a d) && (is_equal_bexp b c))
  | (NOT b1, NOT b2) -> is_equal_bexp b1 b2
  | _ -> false

let rec remove_redundant_bexp : bexp -> bexp = fun bexp ->
  match bexp with
  | NULL -> raise (Error "null used")
  | CONST b -> bexp
  | VAR x -> bexp
  | XOR (b1, b2) -> 
    let new_b1 = remove_redundant_bexp b1 in
    let new_b2 = remove_redundant_bexp b2 in
    if(is_equal_bexp new_b1 new_b2) then (CONST false) else XOR(new_b1, new_b2)
  | AND (b1, b2) -> 
    let new_b1 = remove_redundant_bexp b1 in
    let new_b2 = remove_redundant_bexp b2 in
    if(is_equal_bexp new_b1 new_b2) then (new_b1) else AND(new_b1, new_b2)
  | OR (b1, b2) -> 
    let new_b1 = remove_redundant_bexp b1 in
    let new_b2 = remove_redundant_bexp b2 in
    if(is_equal_bexp new_b1 new_b2) then (new_b1) else OR(new_b1, new_b2)
  | NOT (b1) -> 
    let new_b1 = remove_redundant_bexp b1 in
    NOT(new_b1)

let is_op_node : G.vertex -> bool = fun v ->
  match fst v with
  | Node.AND | Node.OR | Node.NOT | Node.XOR -> true
  | _ -> false


let add_eqn : var list -> G.t -> eqn -> G.t = fun ilist -> fun graph -> fun eqn ->
  let (lv, bexp) = eqn in
  let new_bexp = remove_redundant_bexp bexp in
  let root_node = (Node.VAR lv, 1) in
  let graph_with_root = G.add_vertex graph root_node in
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
  helper graph_with_root root_node new_bexp

let cir2graph : circuit -> G.t = fun cir ->
  let (ilist, olist, elist) = cir in
  let empty_graph = G.empty in
  let graph_with_const = G.add_vertex (G.add_vertex empty_graph (Node.CONST true, 0)) (Node.CONST false, 0) in
  let graph_with_eqns = 
    List.fold_left
    (fun acc -> fun eqn -> 
      add_eqn ilist acc eqn) 
    graph_with_const
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


let get_graph_varlist : G.t -> var list = fun graph ->
  G.fold_vertex (fun v -> fun acc -> 
    match v with 
    | (Node.VAR x, 1) -> x::acc
    | _ -> acc) graph []

let get_graph_ilist : G.t -> var list = fun graph ->
  G.fold_vertex (fun v -> fun acc -> 
    match v with 
    | (Node.VAR x, 0) -> x::acc
    | _ -> acc) graph []


let get_graph_olist : G.t -> var list = fun graph ->
  G.fold_vertex (fun v -> fun acc -> 
    match v with 
    | (Node.VAR x, 1) -> if(G.succ graph v = []) then x::acc else acc
    | _ -> acc)
  graph []

let get_graph_ovlist : G.t -> G.vertex list = fun graph ->
  G.fold_vertex (fun v -> fun acc -> 
    match v with 
    | (Node.VAR x, 1) -> if(G.succ graph v = []) then v::acc else acc
    | _ -> acc)
  graph []


let size_of_graph : G.t -> int = fun graph ->
  let olist_set = BatSet.of_list (get_graph_ovlist graph) in
  let rec size_helper : G.vertex BatSet.t -> G.vertex BatSet.t -> G.vertex BatSet.t = fun toadd -> fun acc ->
    if(BatSet.cardinal toadd = 0) then 
      acc 
    else
      let next_toadd = BatSet.fold (fun vertex -> fun acc -> let pred = G.pred graph vertex in BatSet.union acc (BatSet.of_list pred)) toadd BatSet.empty in
      let new_acc = BatSet.union toadd acc in
      size_helper next_toadd new_acc  
  in
  let whole_set = size_helper olist_set BatSet.empty in
  BatSet.cardinal (BatSet.filter (fun vertex -> is_op_node vertex) whole_set)


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
    let _ = print_node node in
    let _ = print_newline() in
    let _ = print_endline("num of pred : " ^ string_of_int(List.length (G.pred graph node))) in
    let _ = print_node (List.hd (G.pred graph node)) in
    let _ = print_newline() in
    raise (Error ("getting bexp of invalid node"))


let rec get_vlist_expanded_bexp_of_node : G.t -> G.vertex -> var list -> bexp = fun graph -> fun node -> fun vlist ->
  let is_valid_root = is_valid_node graph node in
  if(is_valid_root) then 
    match node with
    | (Node.CONST b, _) -> CONST b
    | (Node.VAR x, 0) -> VAR x
    | (Node.VAR x, 1) -> 
      if (List.mem x vlist) then VAR x else
      let pred = G.pred graph node in
      let var_node = List.nth pred 0 in
      get_vlist_expanded_bexp_of_node graph var_node vlist
    | (Node.AND, _) -> 
      let pred = G.pred graph node in
      let (b1_node, b2_node) = (List.nth pred 0, List.nth pred 1) in
      AND (get_vlist_expanded_bexp_of_node graph b1_node vlist, get_vlist_expanded_bexp_of_node graph b2_node vlist) 
    | (Node.OR, _) -> 
      let pred = G.pred graph node in
      let (b1_node, b2_node) = (List.nth pred 0, List.nth pred 1) in
      OR (get_vlist_expanded_bexp_of_node graph b1_node vlist, get_vlist_expanded_bexp_of_node graph b2_node vlist) 
    | (Node.XOR, _) -> 
      let pred = G.pred graph node in
      let (b1_node, b2_node) = (List.nth pred 0, List.nth pred 1) in
      XOR (get_vlist_expanded_bexp_of_node graph b1_node vlist, get_vlist_expanded_bexp_of_node graph b2_node vlist) 
    | (Node.NOT, _) -> 
      let pred = G.pred graph node in
      let b1_node= List.nth pred 0 in
      NOT (get_vlist_expanded_bexp_of_node graph b1_node vlist) 
    | _ -> 
      let _ = print_node node in 
      let _ = print_newline() in
      let _ = print_string("num of pred : " ^ string_of_int(List.length (G.pred graph node))) in
      raise (Error ("expand invalid node"))
  else 
    let _ = print_node node in
    let _ = print_newline() in
    let _ = print_string("num of pred : " ^ string_of_int(List.length (G.pred graph node))) in
    raise (Error ("expand invalid node"))
 


let get_bexp_of_var : G.t -> var -> bexp = fun graph -> fun var ->
  let var_node = (Node.VAR var, 1) in
  let is_valid_root = is_valid_node graph var_node in
  let pred = if(is_valid_root) then List.nth (G.pred graph var_node) 0 else raise (Error ("invalid var node : " ^ var)) in
  get_bexp_of_node graph pred  
 

let print_graph : G.t -> unit = fun graph ->
  let tgt_vlist = get_graph_varlist graph in
  let _ =List.map (fun v -> print_string(v ^ " = "); Pp.print_bexp (get_bexp_of_var graph v);print_newline()) tgt_vlist
  in 
  ()



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
    | _ -> 
      let _ = print_node node in 
      let _ = print_newline() in
      let _ = print_string("num of pred : " ^ string_of_int(List.length (G.pred graph node))) in
      raise (Error ("expand invalid node"))
  else 
    let _ = print_node node in
    let _ = print_newline() in
    let _ = print_string("num of pred : " ^ string_of_int(List.length (G.pred graph node))) in
    let _ = print_node (List.nth (G.pred graph node) 0) in
    let _ = print_graph graph in
    raise (Error ("expand invalid node"))
 




let get_mult_depth_of_node : G.t -> G.vertex -> int = fun graph -> fun node ->
  let expanded_bexp = get_expanded_bexp_of_node graph node in
  get_mult_depth_expanded_bexp expanded_bexp 
(*

let rec alpha_subst : (var, var) BatMap.t -> bexp -> bexp = fun subst -> fun bexp ->
  match bexp with
  | NULL -> raise (Error "null is used")
  | CONST _ -> bexp
  | VAR x -> if (BatMap.mem x subst) then VAR (BatMap.find x subst) else bexp 
  | AND (b1, b2) -> 
    let alpha_b1 = alpha_subst subst b1 in
    let alpha_b2 = alpha_subst subst b2 in
    AND (alpha_b1, alpha_b2)
  | OR (b1, b2) -> 
    let alpha_b1 = alpha_subst subst b1 in
    let alpha_b2 = alpha_subst subst b2 in
    OR (alpha_b1, alpha_b2)
  | XOR (b1, b2) -> 
    let alpha_b1 = alpha_subst subst b1 in
    let alpha_b2 = alpha_subst subst b2 in
    XOR (alpha_b1, alpha_b2)
  | NOT b1 -> 
    let alpha_b1 = alpha_subst subst b1 in
    NOT alpha_b1


let rec alpha_conv : (bexp * bexp * bexp) -> (bexp * bexp) = fun (old_bexp, new_bexp, tgt_bexp) ->
  let old_vlist = get_bexp_varlist old_bexp in
  let new_vlist = get_bexp_varlist new_bexp in
  (*let tgt_vlist = get_bexp_varlist tgt_bexp in
  let vlist_to_conv = List.filter (fun x -> List.mem x tgt_vlist) (list_merge new_vlist old_vlist) in*)
  let vlist_to_conv = list_merge new_vlist old_vlist in 
  let subst_list = List.mapi (fun i -> fun x -> (x, "tmpvar#"^(string_of_int i))) vlist_to_conv in
  let subst = List.fold_left (fun map -> fun (old_v, tmp_v) -> BatMap.add (old_v) (tmp_v) map) BatMap.empty subst_list in
  (alpha_subst subst old_bexp, alpha_subst subst new_bexp)  


let rec is_equal_bexp : bexp -> bexp -> bool = fun b1 -> fun b2 ->
  match (b1, b2) with
  | (NULL, _) | (_, NULL) -> raise (Error "null used")
  | (CONST b1, CONST b2) -> (b1 = b2)
  | (VAR v1, VAR v2) -> (v1 = v2)
  | (AND (a, b), AND(c, d)) 
  | (XOR (a, b), XOR(c, d)) 
  | (OR (a, b), OR(c, d)) -> ((is_equal_bexp a c) && (is_equal_bexp b d)) || ((is_equal_bexp a d) && (is_equal_bexp b c))
  | (NOT b1, NOT b2) -> is_equal_bexp b1 b2
  | _ -> false


let rec mem_subst : bexp -> (bexp * bexp) list -> bool = fun key -> fun subst ->
  match subst with
  | [] -> false 
  | (b1, b2)::tl -> if(is_equal_bexp b1 key) then true else mem_subst key tl

let rec find_subst : bexp -> (bexp * bexp) list -> bexp = fun key -> fun subst ->
  match subst with
  | [] -> raise (Error "Key Not Found")
  | (b1, b2)::tl -> if(is_equal_bexp b1 key) then b2 else find_subst key tl


let rec substitute_bexp : (bexp * bexp) list -> bexp -> bexp = fun subst -> fun bexp ->
  (*let select_index = let _ = Random.self_init() in Random.int 500000 in
  let _ = if(select_index < 2) then ((print_subst subst);(Pp.print_bexp bexp);print_newline()) else () in*)
  match bexp with
  | NULL -> raise (Error "null is used")
  | CONST _ | VAR _ -> if (mem_subst bexp subst) then find_subst bexp subst else bexp
  | AND (b1, b2) -> 
    let subst_b1 = substitute_bexp subst b1 in
    let subst_b2 = substitute_bexp subst b2 in
    let b1b2 = AND (subst_b1, subst_b2) in
    if(mem_subst b1b2 subst) then find_subst b1b2 subst else b1b2
  | OR (b1, b2) -> 
    let subst_b1 = substitute_bexp subst b1 in
    let subst_b2 = substitute_bexp subst b2 in
    let b1b2 = OR (subst_b1, subst_b2) in
    if(mem_subst b1b2 subst) then find_subst b1b2 subst else b1b2
  | XOR (b1, b2) -> 
    let subst_b1 = substitute_bexp subst b1 in
    let subst_b2 = substitute_bexp subst b2 in
    let b1b2 = XOR (subst_b1, subst_b2) in
    if(mem_subst b1b2 subst) then find_subst b1b2 subst else b1b2
  | NOT b1 -> 
    let subst_b1 = substitute_bexp subst b1 in
    let nb1 = NOT subst_b1 in
    if(mem_subst nb1 subst) then find_subst nb1 subst else nb1
 
 
(*  let vlist = get_bexp_varlist bexp in
  List.fold_left (fun acc -> fun v -> subst_once acc) bexp vlist
*)

let unify : G.t -> bexp -> G.vertex -> (bexp * bexp) list = fun graph -> fun old -> fun tgt_node ->
  let empty_subst = [] in
  let rec unify_helper : (bexp * bexp) list -> bexp -> G.vertex -> (bexp * bexp) list = 
  fun subst -> fun old -> fun tgt_node ->
    match (old, (fst tgt_node)) with
    | (NULL, _) -> raise (Error "null is used")
    | (CONST b1, Node.CONST b2) -> subst (*if (b1 = b2) then subst else subst @ [((CONST b1), (CONST b2))] *)
    | (CONST b, Node.VAR x) ->  subst (* @ [(CONST b, VAR x)] *)
    | (CONST x, _) -> let tgt_bexp = get_bexp_of_node graph tgt_node in subst (*@ [(CONST x, tgt_bexp)]*)
    | (VAR x, Node.CONST b) -> subst (*@ [(VAR x, CONST b)] *)
    | (VAR x1, Node.VAR x2) -> if (x1 = x2) then subst else subst @ [(VAR x1, VAR x2)] 
    | (VAR x, _) -> let tgt_bexp = get_bexp_of_node graph tgt_node in subst @ [(VAR x, tgt_bexp)] 
    | (AND (b1, b2), Node.AND)  
    | (OR (b1, b2), Node.OR)  
    | (XOR (b1, b2), Node.XOR) -> 
      let pred = G.pred graph tgt_node in
      let tgt_b1 = List.nth pred 0 in
      let tgt_b2 = List.nth pred 1 in
      let subst_with_b1 = unify_helper subst b1 tgt_b1 in
      let subst_with_b1_b2 = unify_helper subst_with_b1 (substitute_bexp subst_with_b1 b2) tgt_b2 in
      subst_with_b1_b2
    | (NOT b1, Node.NOT) -> 
      let pred = G.pred graph tgt_node in
      let tgt_b1 = List.nth pred 0 in
      let subst_with_b1 = unify_helper subst b1 tgt_b1 in
      subst_with_b1
    | (_, Node.VAR x) -> 
      if (snd tgt_node = 0) then 
        subst @ [(old, VAR x)] 
      else
        let pred = G.pred graph tgt_node in
        if(List.length pred = 1) then unify old (List.nth pred 0) else raise (Error "unify error : invalid var " ^ x)
    | (_, Node.CONST x) -> subst (*@ [(old, CONST x)]*)
    | _ -> let tgt_bexp = get_bexp_of_node graph tgt_node in subst @ [(old, tgt_bexp)]
  in
  unify_helper empty_subst old tgt_node

(* assume : tgt is var node *)
let graph_opt_by_case : var list -> var list -> G.t -> G.vertex -> (bexp * bexp) -> G.t = 
fun tgt_vlist -> fun ilist ->  fun graph -> fun tgt_node -> fun (old_bexp, new_bexp) ->
  let (old_bexp, new_bexp) = alpha_conv (old_bexp, new_bexp, VAR "TODO") in
  let subst = unify graph old_bexp tgt_node in
  (*let _ = print_subst subst in*)
  let sub_old = substitute_bexp subst old_bexp in
  let sub_old_vlist = get_bexp_varlist sub_old in
  let sub_new = substitute_bexp subst new_bexp in
  let sub_new_vlist = get_bexp_varlist sub_new in
  let new_vlist = get_bexp_varlist new_bexp in
  let is_valid_replace = ((List.length (list_inter sub_old_vlist new_vlist)) = 0) && (list_subset sub_old_vlist sub_new_vlist) && (list_subset sub_new_vlist sub_old_vlist) in
  if(not is_valid_replace) then
    graph
  else
    let before_depth = get_mult_depth_of_node graph tgt_node in
    let pred = G.pred graph tgt_node in
    let lv = match tgt_node with | (Node.VAR x, _) -> x | _ -> raise (Error "trying to opt non-var node") in
    let _ = if(List.length pred = 1) then () else raise (Error "trying to opt non-var node") in
    let graph_without_edge = G.remove_edge graph (List.nth pred 0) tgt_node in
    (*let graph_without_edge = G.remove_edge graph_without_edge tgt_node (List.nth pred 0) in*)
    let graph_with_new_tgt = add_eqn ilist graph_without_edge (lv, sub_new) in
    (*let _ = print_graph graph_with_new_tgt tgt_vlist in*)
    let after_depth = get_mult_depth_of_node graph_with_new_tgt tgt_node in
    if (after_depth < before_depth) then 
      let tgt_bexp = get_vlist_expanded_bexp_of_node graph tgt_node sub_old_vlist in
      let _ = print_endline("pattern matched!") in
      let _ = print_subst subst in
      let _ = print_string("\nold bexp : "); Pp.print_bexp old_bexp in
      let _ = print_string("\nnew bexp : "); Pp.print_bexp new_bexp in
      let _ = print_string("\ntgt bexp     : "); Pp.print_bexp tgt_bexp in
      let _ = print_string("\nsub old bexp : "); Pp.print_bexp sub_old in
      let _ = print_string ("\nis_tgt_subold_same : " ^ (string_of_bool (is_equal_bexp sub_old tgt_bexp))) in
      let _ = print_string("\nsub new bexp : "); Pp.print_bexp sub_new in
      let _ = print_endline ("\nbefore depth : " ^ (string_of_int before_depth)) in
      let _ = print_endline ("after depth : " ^ (string_of_int after_depth)) in
      let _ = print_endline ("graph replaced\n\n") in
      (*let _ = print_graph graph_with_new_tgt (get_graph_varlist graph_with_new_tgt) in*)
      graph_with_new_tgt 
    else
      graph
    
  
let node_opt_by_case_list : var list -> var list -> G.t -> G.vertex -> (bexp * bexp) list -> G.t = fun tgt_vlist -> fun ilist -> fun graph -> fun tgt_node -> fun case_list ->
  (*let _ = print_endline("node_opt is called " ^ (string_of_int (List.length case_list))) in*)
  List.fold_left (fun acc -> fun case -> graph_opt_by_case tgt_vlist ilist acc tgt_node case) graph case_list
 
let commutative_bexp_list : bexp -> bexp list = fun bexp -> 
  let rec commutative_bexp_list : bexp -> int -> (bexp list * int) = fun bexp -> fun num ->
    if(num > 12) then 
      ([bexp], num) 
    else
      match bexp with
      | NULL -> raise (Error "null is used")
      | CONST _ | VAR _ -> ([bexp], num)
      | AND (b1, b2) -> 
        let (com_b1, num_b1) = commutative_bexp_list b1 (num+1) in
        let (com_b2, num_b2) = commutative_bexp_list b2 num_b1 in
        let combination = List.map (fun b1 -> (List.map (fun b2 -> ((b1, b2)::(b2, b1)::[])) com_b2)) com_b1 in
        let flatten : (bexp * bexp) list = List.concat (List.concat combination) in
        (List.map (fun (b1, b2) -> AND (b1, b2)) flatten, num_b2)
      | OR (b1, b2) -> 
        let (com_b1, num_b1) = commutative_bexp_list b1 (num+1) in
        let (com_b2, num_b2) = commutative_bexp_list b2 num_b1 in
        let combination = List.map (fun b1 -> (List.map (fun b2 -> ((b1, b2)::(b2, b1)::[])) com_b2)) com_b1 in
        let flatten : (bexp * bexp) list = List.concat (List.concat combination) in
        (List.map (fun (b1, b2) -> OR (b1, b2)) flatten, num_b2)
      | XOR (b1, b2) -> 
        let (com_b1, num_b1) = commutative_bexp_list b1 (num+1) in
        let (com_b2, num_b2) = commutative_bexp_list b2 num_b1 in
        let combination = List.map (fun b1 -> (List.map (fun b2 -> ((b1, b2)::(b2, b1)::[])) com_b2)) com_b1 in
        let flatten : (bexp * bexp) list = List.concat (List.concat combination) in
        (List.map (fun (b1, b2) -> XOR (b1, b2)) flatten, num_b2)
      | NOT b1 -> 
        let (com_b1, num_b1) = commutative_bexp_list b1 num in
        (List.map (fun b1 -> NOT b1) com_b1, num_b1)
  in
  (fst (commutative_bexp_list bexp 0))

let commutative_case_list : (bexp * bexp) -> (bexp * bexp) list = fun (old_b, new_b) ->
  let com_old = commutative_bexp_list old_b in
  List.map (fun x -> (x, new_b)) com_old

let graph_opt_by_case_file : var list -> var list -> G.t -> string -> G.t = fun tgt_var_list -> fun ilist -> fun graph -> fun case_filename ->
  let input_case = open_in (case_filename) in
  let lexbuf_case = Lexing.from_channel input_case in
  let case_list = CaseParser.main CaseLexer.token lexbuf_case in
  (* TODO : commutative function *)
  let com_case_list_list = List.map (fun x -> commutative_case_list x) case_list in
  let com_case_list = (List.concat com_case_list_list) in
  let graph_opt_once : G.t -> G.t = fun graph ->
    let _ = print_endline("\n\ngraph_opt once called") in
    List.fold_left
    (fun acc_graph -> fun tgt_var ->
      let tgt_node = (Node.VAR tgt_var, 1) in
      node_opt_by_case_list tgt_var_list ilist acc_graph tgt_node com_case_list
    )
    graph
    tgt_var_list
  in
  let rec opt_iter : G.t -> int -> G.t = fun acc_graph -> fun iter ->
    if(iter = 0) then acc_graph else opt_iter (graph_opt_once acc_graph) (iter-1)
  (* TODO : 실험결과 시간 보고 fixpoint로 구현 *)
  in 
  let _ = print_endline("\n\ngraph_opt called") in
  opt_iter graph 4

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
*)
