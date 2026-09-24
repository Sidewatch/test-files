%{
/* Lex/Flex: a tokenizer for a tiny calculator language. */
#include <stdio.h>
#include <stdlib.h>
#include "parser.tab.h"
int line_no = 1;
%}

%option noyywrap nounput noinput

DIGIT   [0-9]
ID      [a-zA-Z_][a-zA-Z0-9_]*

%%

{DIGIT}+"."{DIGIT}*   { yylval.num = atof(yytext); return NUMBER; }
{DIGIT}+              { yylval.num = atof(yytext); return NUMBER; }
"let"                 { return LET; }
"print"               { return PRINT; }
{ID}                  { yylval.name = strdup(yytext); return IDENT; }
[-+*/=();]            { return yytext[0]; }
"#".*                 { /* comment */ }
\n                    { line_no++; }
[ \t\r]+              { /* skip whitespace */ }
.                     { fprintf(stderr, "line %d: unexpected '%s'\n", line_no, yytext); }

%%
