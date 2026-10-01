/* ── Definitions section: C prologue, options, named patterns, start conditions ── */
%{
/* Lex/Flex: a tokenizer for a small stock-query language. */
// C++-style comment inside the prologue
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"

#define MAX_STR 4096
#define VERSION "1.0"

static int line_no = 1;
static int col_no = 1;
static char string_buf[MAX_STR];
static char *string_ptr;
static int comment_depth = 0;

static void track(void) { col_no += yyleng; }
static char *dup(const char *s) { return strdup(s); }
%}

%option noyywrap nounput noinput
%option yylineno
%option case-insensitive
%option never-interactive
%option prefix="stock_"
%option outfile="lex.yy.c"
%option reentrant bison-bridge

 /* indented comment lines are copied verbatim in the definitions section */

%x STRING
%x BLOCK_COMMENT
%s INCLUDE
%x PRAGMA

 /* ── Rare constructs: definitions ── */
%top{
#define _GNU_SOURCE 1
}
%option stack
%option yywrap
%option warn nodefault
%option 8bit
%option align
%option ecs meta-ecs
%option read
%option stdout
%option yymore
%option debug
%option verbose
%option extra-type="struct scan_extra *"
%option header-file="lex.h"
%option tables-file="lex.tables"
%option yylineno
%option bison-locations
%option noyyalloc noyyrealloc noyyfree
%option nodefault
%xs RARE_EXCL
%s RARE_INCL
%x RARE_A RARE_B

WORD        [[:alpha:]]+
ANYCLASS    [[:alnum:][:blank:][:cntrl:][:digit:][:graph:][:lower:][:print:][:punct:][:space:][:upper:][:xdigit:]]
UNION       [a-z]{+}[0-9]
SUBTRACT    [a-z]{-}[aeiou]
CI          (?i:select)
CS          (?-i:Select)
DOTALL      (?s:.)
EXT         (?x: a b c )
COMMENTRE   (?# inline regex comment)abc
ALT         (foo|bar|baz)
QUANT       a{2}b{2,}c{1,3}d*e+f?
LAZY        x*? y+? z??
ESC         \\[0-7]{1,3}|\\x[0-9a-fA-F]{1,2}|\\[abfnrtv\\"']

DIGIT       [0-9]
HEXDIGIT    [0-9a-fA-F]
LETTER      [a-zA-Z_]
ID          {LETTER}({LETTER}|{DIGIT})*
INT         {DIGIT}+
FLOAT       {DIGIT}+"."{DIGIT}*([eE][-+]?{DIGIT}+)?
HEX         0[xX]{HEXDIGIT}+
SKU         [A-Z]{2,4}-[0-9]{3,}
WS          [ \t\r]+
NEWLINE     \n|\r\n
STRCHAR     [^"\\\n]
ESCAPE      \\(["\\nrt]|x{HEXDIGIT}{2})

%%

 /* ── Rules section ── */

 /* Comments */
"//".*                    { /* line comment */ }
"/*"                      { comment_depth = 1; BEGIN(BLOCK_COMMENT); }
<BLOCK_COMMENT>{
    "/*"                  { comment_depth++; }
    "*/"                  { if (--comment_depth == 0) BEGIN(INITIAL); }
    [^*/\n]+              { /* eat comment text */ }
    [*/]                  { /* lone * or / */ }
    \n                    { line_no++; }
    <<EOF>>               { fprintf(stderr, "unterminated comment\n"); return 0; }
}

 /* Keywords (case-insensitive due to %option) */
select|from|where         { return KEYWORD; }
"insert"                  { return INSERT; }
"update"/{WS}+"set"       { return UPDATE; }
"limit"                   { return LIMIT; }
"and"|"or"|"not"          { yylval.str = dup(yytext); return LOGICAL; }
"true"|"false"            { yylval.num = (yytext[0] == 't'); return BOOLEAN; }
"null"                    { return NULL_LIT; }

 /* Literals */
{SKU}                     { yylval.str = dup(yytext); return SKU; }
{HEX}                     { yylval.num = strtol(yytext, NULL, 16); return NUMBER; }
{FLOAT}                   { yylval.num = atof(yytext); return NUMBER; }
{INT}                     { yylval.num = atoi(yytext); return NUMBER; }
{ID}                      { yylval.str = dup(yytext); return IDENT; }
`[^`]+`                   { yylval.str = dup(yytext); return QUOTED_IDENT; }

 /* Operators */
"<="|">="|"<>"|"!="|"=="  { return CMP; }
"<<"|">>"                 { return SHIFT; }
"&&"                      { return AND; }
"||"                      { return OR; }
[-+*/%=<>(),;.]           { return yytext[0]; }
"\\"                      { return BACKSLASH; }
[\[\]{}]                  { return yytext[0]; }

 /* Strings with start condition */
\"                        { string_ptr = string_buf; BEGIN(STRING); }
<STRING>{
    \"                    { *string_ptr = '\0'; BEGIN(INITIAL); yylval.str = dup(string_buf); return STRING_LIT; }
    \\n                   { *string_ptr++ = '\n'; }
    \\t                   { *string_ptr++ = '\t'; }
    \\x{HEXDIGIT}{2}      { *string_ptr++ = (char) strtol(yytext + 2, NULL, 16); }
    \\(.|\n)              { *string_ptr++ = yytext[1]; }
    {STRCHAR}+            { char *p = yytext; while (*p) *string_ptr++ = *p++; }
    \n                    { fprintf(stderr, "line %d: newline in string\n", line_no); BEGIN(INITIAL); }
    <<EOF>>               { fprintf(stderr, "unterminated string\n"); return 0; }
}

 /* Directives with trailing context and REJECT/yymore */
^"#include"{WS}*          { BEGIN(INCLUDE); }
<INCLUDE>[^ \t\n]+        { printf("include %s\n", yytext); BEGIN(INITIAL); }
^"#pragma"                { BEGIN(PRAGMA); yymore(); }
<PRAGMA>.*                { BEGIN(INITIAL); }
foo|foobar                { ECHO; REJECT; }
a[bc]+/d                  { yyless(2); }
x{2,3}y?z*                { unput('!'); }
[a-z]{-}[aeiou]           { /* character class subtraction */ }
"["[^]\n]*"]"             { return BRACKETED; }
\x41\102\u0043            { /* hex, octal escapes */ }
[[:alpha:]][[:alnum:]_]*  { return NAME; }
[[:digit:]]+              { return DIGITS; }
(ab|cd)+$                 { /* end-of-line anchor */ }

 /* ── Rare constructs: rules ── */
<*>"@any"                 { /* active in every start condition */ }
<RARE_A,RARE_B>"@ab"      { yy_push_state(RARE_EXCL); }
<RARE_EXCL>"@pop"         { yy_pop_state(); }
<RARE_INCL>"@top"         { BEGIN(yy_top_state()); }
<INITIAL,RARE_INCL>"@init" { BEGIN(INITIAL); }
^"@bol"                   { /* beginning of line */ }
"@eol"$                   { /* end of line */ }
"@trail"/"ing"            { /* trailing context */ }
"@trail2"/[0-9]+          { ECHO; }
^"@both"$                 { }
"@alt1"|"@alt2"|"@alt3"   { return 1; }
"@fallthrough" |
"@fall2"                  { return 2; }
{WORD}{1,3}               { yylval.str = dup(yytext); return WORD; }
{ANYCLASS}                { }
{UNION}|{SUBTRACT}        { }
{CI}{CS}{DOTALL}{EXT}     { }
{COMMENTRE}               { }
\"({ESC}|[^"\\\n])*\"        { }
"\""({ESC}|[^"\\\n])*"\""        { }
'[^'\n]*'                { return CHAR_LIT; }
"@caret^"                 { }
[\^\-\]a]                { }
[^\n]*                   { }
[\x00-\x1f\x7f]          { }
\0|\00|\000|\x00        { }
"@dollar$"                { }
.|\n                      { }
"@actions"                {
    /* multi-line action with braces, strings and comments */
    char buf[] = "}{ \" // not a comment";
    if (yyleng > 1) { yyless(1); } else { yymore(); }
    unput('x'); { int c = input(); (void)c; }
    yyterminate();
}
"@yy"                     { yyrestart(yyin); YY_FLUSH_BUFFER; yy_flush_buffer(YY_CURRENT_BUFFER); }
"@buf"                    { YY_BUFFER_STATE b = yy_scan_string("abc"); yy_switch_to_buffer(b); yy_delete_buffer(b); }
"@start"                  { printf("%d\n", YY_START); BEGIN(YY_START); }
"@brk"                    { YY_BREAK }
"@reject"                 { REJECT; }
"@echo"                   ECHO;
"@single-line-action"     return 3;
%{
  /* indented-code block inside the rules section */
  static int rare_counter;
%}
"@count"                  { rare_counter++; }
<<EOF>>                   { yyterminate(); }

 /* Whitespace and fallbacks */
{NEWLINE}                 { line_no++; col_no = 1; }
{WS}                      { track(); }
<<EOF>>                   { return 0; }
.                         { fprintf(stderr, "line %d: unexpected '%s'\n", line_no, yytext); }

%%

/* ── User code section ── */
int main(int argc, char **argv)
{
    int token;
    if (argc > 1 && !(yyin = fopen(argv[1], "r"))) {
        perror(argv[1]);
        return EXIT_FAILURE;
    }
    while ((token = yylex()) != 0) {
        printf("token %d at line %d: \"%s\"\n", token, line_no, yytext);
    }
    return 0;
}

#define YY_USER_ACTION  col_no += yyleng;
#define YY_DECL int yylex(void)
#define YY_INPUT(buf, result, max_size) { result = fread(buf, 1, max_size, yyin); }
#define YY_NO_INPUT 1
#define YY_NO_UNPUT 1
#define YY_FATAL_ERROR(msg) do { fputs(msg, stderr); exit(2); } while (0)
