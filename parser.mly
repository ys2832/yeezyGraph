(* Ocamlyacc parser for YeezyGraph*)

%{ open Ast %}

/* Punctuation tokens*/
%token SEMI LPAREN RPAREN LBRACE RBRACE COMMA COLON
/* Arithmetic tokens */
%token PLUS MINUS TIMES DIVIDE MOD ASSIGN NOT
/* Logical tokens */
%token EQ NEQ LT LEQ GT GEQ TRUE FALSE AND OR
/* Primitive datatype tokens */
%token INT FLOAT STRING BOOL NULL
/* Control flow tokens */
%token IF ELSE FOR WHILE
/* Function tokens */
%token RETURN VOID MAIN
%token NODE GRAPH 
/*Node tokens*/
%token UNDERSCORE AT 
/* Graph tokens */
%token ADD_NODE REMOVE_NODE ADD_EDGE REMOVE_EDGE
/*Collection tokens*/
%token LIST QUEUE PQUEUE MAP STRUCT
/* STRUCT/BUILT-IN FUNCTION tokens */
%token DOT
/*Infinity tokens*/  
%token INT_MAX INT_MIN FLOAT_MAX FLOAT_MIN
/*number literals*/
%token <int> INT_LITERAL
%token <float> FLOAT_LITERAL
/*string literal*/
%token <string> STR_LITERAL
/* variable names*/
%token <string> ID
%token EOF

%nonassoc NOELSE
%nonassoc ELSE
%right ASSIGN
%left OR
%left AND
%left EQ NEQ
%left LT GT LEQ GEQ
%left PLUS MINUS
%left TIMES DIVIDE MOD
%right NOT NEG
%left DOT
%nonassoc AT
%left ADD_EDGE REMOVE_EDGE
%nonassoc UNDERSCORE
%left ADD_NODE REMOVE_NODE



%start program /*what exactly does this do? - start symbol for the context free grammar for our language*/
%type <Ast.program> program

/* Stopping Point */

%%

program:
  decls EOF { $1 }

decls:
   /* nothing */ { [], [] }
 | decls vdecl { ($2 :: fst $1), snd $1 }
 | decls fdecl { fst $1, ($2 :: snd $1) }
 /* need declarations for collections */

/* returntype functionname(arg1, arg2....)*/
fdecl:
   typ ID LPAREN formals_opt RPAREN LBRACE vdecl_list stmt_list RBRACE
     { { typ = $1;
	 fname = $2;
	 formals = $4;
	 locals = List.rev $7;
	 body = List.rev $8 } }

formals_opt:
    /* nothing */ { [] }
  | formal_list   { List.rev $1 }

formal_list:
    typ ID                   { [($1,$2)] }
  | formal_list COMMA typ ID { ($3,$4) :: $1 }

/* differentiation between primitive and derived types*/
typ:
    INT { Int }
  | FLOAT {Float }
  | STRING { String }
  | BOOL { Bool }
  | VOID { Void }
  /* Is it okay for the following to be listed as this, since we always have a collection of another type?*/
  | QUEUE { Queue }
  | PQUEUE {PQueue }
  | LIST { List }
  | MAP  { Map}
  | STRUCT { Struct } /*Likewise, is this okay since a struct is a complex data type?*/
  | GRAPH { Graph }
  | NODE { Node }
  /* include null? */

vdecl_list:
    /* nothing */    { [] }
  | vdecl_list vdecl { $2 :: $1 }

vdecl:
   typ ID SEMI { ($1, $2) }

stmt_list:
    /* nothing */  { [] }
  | stmt_list stmt { $2 :: $1 }

stmt:
    expr SEMI { Expr $1 }
  | RETURN SEMI { Return Noexpr }
  | RETURN expr SEMI { Return $2 }
  | LBRACE stmt_list RBRACE { Block(List.rev $2) }
  | IF LPAREN expr RPAREN stmt %prec NOELSE { If($3, $5, Block([])) }
  | IF LPAREN expr RPAREN stmt ELSE stmt    { If($3, $5, $7) }
  | FOR LPAREN expr_opt SEMI expr SEMI expr_opt RPAREN stmt
     { For($3, $5, $7, $9) }
  | WHILE LPAREN expr RPAREN stmt { While($3, $5) }

expr_opt:
    /* nothing */ { Noexpr }
  | expr          { $1 }

expr:
    LITERAL          { Literal($1) }
  | TRUE             { BoolLit(true) }
  | FALSE            { BoolLit(false) }
  | ID               { Id($1) }
  | expr PLUS   expr { Binop($1, Add,   $3) }
  | expr MINUS  expr { Binop($1, Sub,   $3) }
  | expr TIMES  expr { Binop($1, Mult,  $3) }
  | expr DIVIDE expr { Binop($1, Div,   $3) }
  | expr EQ     expr { Binop($1, Equal, $3) }
  | expr NEQ    expr { Binop($1, Neq,   $3) }
  | expr LT     expr { Binop($1, Less,  $3) }
  | expr LEQ    expr { Binop($1, Leq,   $3) }
  | expr GT     expr { Binop($1, Greater, $3) }
  | expr GEQ    expr { Binop($1, Geq,   $3) }
  | expr AND    expr { Binop($1, And,   $3) }
  | expr OR     expr { Binop($1, Or,    $3) }
  | MINUS expr %prec NEG { Unop(Neg, $2) }
  | NOT expr         { Unop(Not, $2) }
  | ID ASSIGN expr   { Assign($1, $3) }
  | ID LPAREN actuals_opt RPAREN { Call($1, $3) }
  | LPAREN expr RPAREN { $2 }

actuals_opt:
    /* nothing */ { [] }
  | actuals_list  { List.rev $1 }

actuals_list:
    expr                    { [$1] }
  | actuals_list COMMA expr { $3 :: $1 }
