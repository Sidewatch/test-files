%{
/* Yacc/Bison: a calculator with variables. */
#include <stdio.h>
#include <stdlib.h>
int yylex(void);
void yyerror(const char *s) { fprintf(stderr, "error: %s\n", s); }
double vars[26];
%}

%union { double num; int var; }
%token <num> NUMBER
%token <var> IDENT
%token LET PRINT
%type  <num> expr

%left '+' '-'
%left '*' '/'
%precedence NEG

%%

program : /* empty */
        | program statement ';'
        ;

statement : LET IDENT '=' expr      { vars[$2] = $4; }
          | PRINT expr              { printf("%g\n", $2); }
          ;

expr : NUMBER                       { $$ = $1; }
     | IDENT                        { $$ = vars[$1]; }
     | expr '+' expr                { $$ = $1 + $3; }
     | expr '-' expr                { $$ = $1 - $3; }
     | expr '*' expr                { $$ = $1 * $3; }
     | expr '/' expr                { if ($3 == 0) { yyerror("divide by zero"); YYERROR; } $$ = $1 / $3; }
     | '-' expr %prec NEG           { $$ = -$2; }
     | '(' expr ')'                 { $$ = $2; }
     ;

%%

int main(void) { return yyparse(); }
