%{
/* ── Prologue (C) ──
 * Bison grammar: a stock-ledger command language.
 * TODO: add quoted SKUs
 * FIXME: error recovery drops the rest of the line
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define MAX_SKUS 1024
#define LOG(fmt, ...) fprintf(stderr, "ledger: " fmt "\n", ##__VA_ARGS__)

typedef struct { char sku[16]; long qty; } line_t;
static line_t ledger[MAX_SKUS];
static int count = 0;
static double vars[26];

int yylex(void);
void yyerror(const char *msg);
static long stock_of(const char *sku);
static void add_stock(const char *sku, long qty);
%}

/* ── Bison declarations ── */
%require "3.8"
%defines
%define api.pure full
%define parse.error verbose
%define parse.lac full
%locations
%expect 0
%debug
%verbose
%define api.value.type {union YYSTYPE}
%define api.token.prefix {TOK_}
%define api.symbol.prefix {S_}
%name-prefix "ledger_"
%file-prefix "ledger"
%output "ledger.tab.c"
%skeleton "yacc.c"
%param { void *scanner }
%parse-param { int *result }
%lex-param { int verbose }
%initial-action { *result = 0; }
%code requires {
    #include <stddef.h>
}
%code provides {
    int ledger_parse_file(const char *path);
}
%code top {
    #define _GNU_SOURCE
}

/* ── Semantic values ── */
%union {
    double num;
    long   qty;
    char  *str;
    int    var;
}

/* ── Tokens ── */
%token <num> NUMBER "number"
%token <str> SKU "sku"
%token <var> IDENT "identifier"
%token LET "let" PRINT "print" ADD "add" REMOVE "remove" REPORT "report"
%token IF THEN ELSE WHILE DO END
%token EQ "==" NE "!=" LE "<=" GE ">="
%token ASSIGN ":="
%token EOL "end of line"
%token YYEOF 0 "end of file"

/* ── Types of nonterminals ── */
%type  <num> expr term factor
%type  <qty> quantity
%type  <str> label
%nterm <num> condition

/* ── Precedence and associativity ── */
%precedence LOW
%left  '|'
%left  '&'
%nonassoc EQ NE '<' '>' LE GE
%left  '+' '-'
%left  '*' '/' '%'
%right '^'
%precedence NEG
%right ASSIGN

/* ── Destructors and printers ── */
%destructor { free($$); } <str>
%destructor { LOG("discarding %g", $$); } NUMBER
%printer { fprintf(yyo, "%g", $$); } <num>
%printer { fprintf(yyo, "%s", $$); } <str>

%start program

%%

/* ── Grammar rules ── */

program
    : /* empty */
    | program statement EOL
    | program error EOL { yyerrok; LOG("recovered at line %d", @2.first_line); }
    ;

statement
    : LET IDENT ASSIGN expr          { vars[$2] = $4; }
    | PRINT expr                     { printf("%g\n", $2); }
    | ADD SKU quantity               { add_stock($2, $3); free($2); }
    | REMOVE SKU quantity            { add_stock($2, -$3); free($2); }
    | REPORT label                   { LOG("report %s", $2); free($2); }
    | IF condition THEN statement ELSE statement END
    | WHILE condition DO statement END
    | %empty
    ;

label
    : SKU                            { $$ = $1; }
    | IDENT                          { $$ = strdup("var"); }
    | label '.' SKU                  { $$ = $1; free($3); }
    ;

quantity
    : NUMBER                         { $$ = (long) $1; }
    | '(' expr ')'                   { $$ = (long) $2; }
    ;

condition
    : expr EQ expr                   { $$ = $1 == $3; }
    | expr NE expr                   { $$ = $1 != $3; }
    | expr '<' expr                  { $$ = $1 <  $3; }
    | expr '>' expr                  { $$ = $1 >  $3; }
    | expr LE expr                   { $$ = $1 <= $3; }
    | expr GE expr                   { $$ = $1 >= $3; }
    | condition '&' condition        { $$ = $1 && $3; }
    | condition '|' condition        { $$ = $1 || $3; }
    ;

expr
    : term
    | expr '+' term                  { $$ = $1 + $3; }
    | expr '-' term                  { $$ = $1 - $3; }
    ;

term
    : factor
    | term '*' factor                { $$ = $1 * $3; }
    | term '/' factor                {
                                         if ($3 == 0) {
                                             yyerror("divide by zero");
                                             YYERROR;
                                         }
                                         $$ = $1 / $3;
                                     }
    | term '%' factor                { $$ = (long) $1 % (long) $3; }
    ;

factor
    : NUMBER                         { $$ = $1; }
    | IDENT                          { $$ = vars[$1]; }
    | SKU                            { $$ = (double) stock_of($1); free($1); }
    | '-' factor %prec NEG           { $$ = -$2; }
    | factor '^' factor              { $$ = 1; for (int i = 0; i < (int) $3; i++) $$ *= $1; }
    | '(' expr ')'                   { $$ = $2; }
    | '\'' IDENT '\''                { $$ = vars[$2]; /* char literal tokens */ }
    ;

%%

/* ── Epilogue (C) ── */

static long stock_of(const char *sku)
{
    for (int i = 0; i < count; i++) {
        if (strcmp(ledger[i].sku, sku) == 0) return ledger[i].qty;
    }
    return 0L;
}

static void add_stock(const char *sku, long qty)
{
    for (int i = 0; i < count; i++) {
        if (strcmp(ledger[i].sku, sku) == 0) {
            ledger[i].qty += qty;
            return;
        }
    }
    if (count < MAX_SKUS) {
        snprintf(ledger[count].sku, sizeof ledger[count].sku, "%s", sku);
        ledger[count++].qty = qty;
    }
}

void yyerror(const char *msg)
{
    fprintf(stderr, "error: %s\n", msg);
}

int main(void)
{
    int result = 0;
    return yyparse(&result);
}
