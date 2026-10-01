/* Bison 3.8 — grammar syntax showcase */
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
%defines                        /* Bison 3.8 spells the same thing %header */
%header "ledger.tab.h"
%language "C"
%yacc                           /* POSIX Yacc compatibility */
%no-lines                       /* no #line directives in the output */
%token-table
%expect-rr 0
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
%name-prefix "ledger_"            /* deprecated: use %define api.prefix */
%define api.prefix {ledger_}
%define api.header.include {"ledger.tab.h"}
%define api.filename.type {const char *}
%define api.location.type {struct ledger_loc}
%define api.token.raw false
%define api.push-pull both
%define lr.type ielr
%define lr.default-reduction accepting
%define lr.keep-unreachable-state true
%define parse.assert
%define parse.trace
%define parse.error detailed
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
%code {
    /* unqualified %code: after the Bison-generated declarations */
}
%code top {
    #define _GNU_SOURCE
}

/* ── Directives for other skeletons and parser kinds (kept together; a real
      grammar uses one skeleton) ── */
%glr-parser                     /* generalised LR: enables %merge, %dprec, %?{ } */
%nondeterministic-parser
%pure-parser                    /* deprecated: use %define api.pure */
%error-verbose                  /* deprecated: use %define parse.error verbose */
%code imports { import java.io.*; }
%define api.namespace {ledger}
%define api.value.type variant
%define api.token.constructor
%define api.value.automove
%skeleton "lalr1.cc"
%define api.value.type union
%define api.value.type union-directive
%define api.value.type {struct ledger_value}

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
%token <num> HEXNUMBER 258 "hex number"      /* explicit token number */
%token <str> QUOTED "quoted sku"
%token <num> RATIO "ratio" <qty> COUNT "count" /* several tags in one declaration */
%token PLUSPLUS "++" MINUSMINUS "--" ARROW "->" /* string aliases for operators */

/* ── Types of nonterminals ── */
%type  <num> expr term factor
%type  <qty> quantity
%type  <str> label
%nterm <num> condition
%nterm <num> anything
%nterm untagged
%type  <str> named_sku quoted_sku

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
%destructor { LOG("any tagged symbol"); } <*>
%destructor { LOG("any untagged symbol"); } <>
%destructor { free($$); } <str> label named_sku
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

/* ── Named references, mid-rule actions, predicates ── */

named_sku
    : SKU[name] '.' NUMBER[version]  { $$ = $name; LOG("version %g", $version); }
    | SKU[sku] { $<num>$ = 1; } NUMBER { $$ = $sku; LOG("midrule %g", $<num>2); }
    | SKU[left] '+' SKU[right]       { $$ = $left; free($right); }
    | named_sku[inner] '.' SKU       { $$ = $inner; @$ = @inner; }
    | error { yyclearin; yyerrok; $$ = NULL; }
    ;

quoted_sku
    : '"' SKU '"'                    { $$ = $2; }
    | '"' error '"'                  { $$ = NULL; YYACCEPT; }
    | "quoted sku" %prec LOW         { $$ = $1; YYABORT; }
    | IDENT { $<str>$ = strdup("mid"); } SKU { $$ = $<str>2; (void) $-1; }
    ;

/* GLR-only constructs (valid with %glr-parser): %merge, %dprec, semantic predicates */
anything
    : expr %dprec 1                  { $$ = $1; }
    | label %dprec 2 %merge <ledger_merge> { $$ = 0; }
    | %?{ count > 0 } expr           { $$ = $2; }
    | expr %?{ $1 != 0 }             { $$ = $1; YYBACKUP(NUMBER, $1); }
    | { LOG("recovering: %d", YYRECOVERING()); } %empty
    ;

untagged
    : '\\'                          /* escaped char literals */
    | '\n' | '\t' | '\x41' | '\101'
    | "end of file"
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
