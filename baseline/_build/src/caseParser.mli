type token =
  | EOF
  | TK_opt
  | TK_target
  | TK_input
  | TK_list
  | TK_colon
  | TK_old
  | TK_new
  | TK_bexp
  | TK_LP
  | TK_RP
  | TK_BOOL
  | TK_BOOL_LITERAL of (bool)
  | TK_VAR of (string)
  | TK_AND
  | TK_OR
  | TK_XOR
  | TK_NOT

val main :
  (Lexing.lexbuf  -> token) -> Lexing.lexbuf -> (Circuit.bexp * Circuit.bexp) list
