type token =
  | EOF
  | TK_INPUT_LIST
  | TK_OUTPUT_LIST
  | TK_LPAREN
  | TK_RPAREN
  | TK_EQUAL
  | TK_SEMICOLON
  | TK_CONST_BOOL of (bool)
  | TK_VAR of (string)
  | TK_OR
  | TK_AND
  | TK_NOT

open Parsing;;
let _ = parse_error;;
# 2 "src/eqnParser.mly"
	open Circuit
	exception ParsingError
# 21 "src/eqnParser.ml"
let yytransl_const = [|
    0 (* EOF *);
  257 (* TK_INPUT_LIST *);
  258 (* TK_OUTPUT_LIST *);
  259 (* TK_LPAREN *);
  260 (* TK_RPAREN *);
  261 (* TK_EQUAL *);
  262 (* TK_SEMICOLON *);
  265 (* TK_OR *);
  266 (* TK_AND *);
  267 (* TK_NOT *);
    0|]

let yytransl_block = [|
  263 (* TK_CONST_BOOL *);
  264 (* TK_VAR *);
    0|]

let yylhs = "\255\255\
\001\000\002\000\002\000\003\000\003\000\004\000\005\000\005\000\
\005\000\005\000\005\000\000\000"

let yylen = "\002\000\
\010\000\002\000\001\000\002\000\001\000\004\000\013\000\001\000\
\001\000\003\000\002\000\002\000"

let yydefred = "\000\000\
\000\000\000\000\000\000\012\000\000\000\000\000\000\000\002\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\001\000\004\000\000\000\008\000\009\000\000\000\000\000\
\000\000\011\000\006\000\000\000\000\000\010\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\007\000"

let yydgoto = "\002\000\
\004\000\007\000\015\000\016\000\024\000"

let yysindex = "\002\000\
\009\255\000\000\006\255\000\000\004\255\004\255\008\255\000\000\
\013\255\011\255\004\255\012\255\014\255\015\255\017\000\014\255\
\253\254\000\000\000\000\016\255\000\000\000\000\253\254\003\255\
\017\255\000\000\000\000\253\254\010\255\000\000\018\255\019\255\
\020\255\022\255\021\255\023\255\024\255\025\255\026\255\000\000"

let yyrindex = "\000\000\
\000\000\000\000\000\000\000\000\000\000\029\255\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\019\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000"

let yygindex = "\000\000\
\000\000\251\255\012\000\000\000\235\255"

let yytablesize = 35
let yytable = "\020\000\
\008\000\026\000\001\000\021\000\022\000\012\000\030\000\023\000\
\027\000\003\000\005\000\006\000\028\000\009\000\010\000\011\000\
\018\000\013\000\005\000\017\000\031\000\014\000\033\000\025\000\
\035\000\032\000\029\000\019\000\034\000\040\000\037\000\036\000\
\039\000\038\000\003\000"

let yycheck = "\003\001\
\006\000\023\000\001\000\007\001\008\001\011\000\028\000\011\001\
\006\001\001\001\005\001\008\001\010\001\006\001\002\001\005\001\
\000\000\006\001\000\000\005\001\011\001\008\001\004\001\008\001\
\003\001\008\001\010\001\016\000\009\001\004\001\008\001\011\001\
\008\001\010\001\006\001"

let yynames_const = "\
  EOF\000\
  TK_INPUT_LIST\000\
  TK_OUTPUT_LIST\000\
  TK_LPAREN\000\
  TK_RPAREN\000\
  TK_EQUAL\000\
  TK_SEMICOLON\000\
  TK_OR\000\
  TK_AND\000\
  TK_NOT\000\
  "

let yynames_block = "\
  TK_CONST_BOOL\000\
  TK_VAR\000\
  "

let yyact = [|
  (fun _ -> failwith "parser")
; (fun __caml_parser_env ->
    let _3 = (Parsing.peek_val __caml_parser_env 7 : 'varlist) in
    let _7 = (Parsing.peek_val __caml_parser_env 3 : 'varlist) in
    let _9 = (Parsing.peek_val __caml_parser_env 1 : 'eqnlist) in
    Obj.repr(
# 45 "src/eqnParser.mly"
                                                                                                        ( (_3, _7, _9) )
# 117 "src/eqnParser.ml"
               : Circuit.circuit))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 1 : string) in
    let _2 = (Parsing.peek_val __caml_parser_env 0 : 'varlist) in
    Obj.repr(
# 48 "src/eqnParser.mly"
                  ( _1::_2 )
# 125 "src/eqnParser.ml"
               : 'varlist))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 49 "src/eqnParser.mly"
          ( _1::[] )
# 132 "src/eqnParser.ml"
               : 'varlist))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 1 : 'eqn) in
    let _2 = (Parsing.peek_val __caml_parser_env 0 : 'eqnlist) in
    Obj.repr(
# 52 "src/eqnParser.mly"
               ( _1::_2 )
# 140 "src/eqnParser.ml"
               : 'eqnlist))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : 'eqn) in
    Obj.repr(
# 53 "src/eqnParser.mly"
       ( _1::[] )
# 147 "src/eqnParser.ml"
               : 'eqnlist))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 3 : string) in
    let _3 = (Parsing.peek_val __caml_parser_env 1 : 'bexp) in
    Obj.repr(
# 56 "src/eqnParser.mly"
                                     ( (_1, _3) )
# 155 "src/eqnParser.ml"
               : 'eqn))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 11 : string) in
    let _5 = (Parsing.peek_val __caml_parser_env 8 : string) in
    let _10 = (Parsing.peek_val __caml_parser_env 3 : string) in
    let _12 = (Parsing.peek_val __caml_parser_env 1 : string) in
    Obj.repr(
# 60 "src/eqnParser.mly"
                                                                                                        ( 
	  if( (_2 = _10) && (_5 = _12) ) then XOR(VAR _2, VAR _5) else let _ = print_string(_2 ^ _5) in raise ParsingError 
	  )
# 167 "src/eqnParser.ml"
               : 'bexp))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : bool) in
    Obj.repr(
# 63 "src/eqnParser.mly"
                 ( CONST _1 )
# 174 "src/eqnParser.ml"
               : 'bexp))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 64 "src/eqnParser.mly"
          ( VAR _1 )
# 181 "src/eqnParser.ml"
               : 'bexp))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 2 : 'bexp) in
    let _3 = (Parsing.peek_val __caml_parser_env 0 : 'bexp) in
    Obj.repr(
# 65 "src/eqnParser.mly"
                    ( AND(_1, _3) )
# 189 "src/eqnParser.ml"
               : 'bexp))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 0 : 'bexp) in
    Obj.repr(
# 66 "src/eqnParser.mly"
               (NOT _2)
# 196 "src/eqnParser.ml"
               : 'bexp))
(* Entry main *)
; (fun __caml_parser_env -> raise (Parsing.YYexit (Parsing.peek_val __caml_parser_env 0)))
|]
let yytables =
  { Parsing.actions=yyact;
    Parsing.transl_const=yytransl_const;
    Parsing.transl_block=yytransl_block;
    Parsing.lhs=yylhs;
    Parsing.len=yylen;
    Parsing.defred=yydefred;
    Parsing.dgoto=yydgoto;
    Parsing.sindex=yysindex;
    Parsing.rindex=yyrindex;
    Parsing.gindex=yygindex;
    Parsing.tablesize=yytablesize;
    Parsing.table=yytable;
    Parsing.check=yycheck;
    Parsing.error_function=parse_error;
    Parsing.names_const=yynames_const;
    Parsing.names_block=yynames_block }
let main (lexfun : Lexing.lexbuf -> token) (lexbuf : Lexing.lexbuf) =
   (Parsing.yyparse yytables 1 lexfun lexbuf : Circuit.circuit)
