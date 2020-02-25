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

val main :
  (Lexing.lexbuf  -> token) -> Lexing.lexbuf -> Circuit.circuit
