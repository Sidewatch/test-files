% SWI-Prolog 9.4 (ISO core plus SWI extensions) — syntax showcase
%% ── Comments ──
% Prolog showcase: a warehouse inventory knowledge base.
% TODO: move the facts into a separate file
/* A block comment
   spanning lines. FIXME: cut stock via assert/retract only. */

%! stock(?Sku, ?Bin, ?Qty) is nondet.
%
%  Doc comment in PlDoc style.
%  @param Sku the product code
%  @see reorder/2

%% ── Directives ──
:- module(warehouse, [stock/3, reorder/2, total_value/1, main/0]).
:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(dcg/basics)).
:- use_module(library(aggregate), [aggregate_all/3]).
:- set_prolog_flag(double_quotes, codes).
:- dynamic stock/3, price/2.
:- discontiguous price/2.
:- initialization(main).
:- op(700, xfx, ===>).
:- op(200, xfy, ^^).
:- op(9, fx, #).
:- ensure_loaded(library(readutil)).
:- table path/2.

%% ── Facts ──
product(ac1001, 'Widget, large', 19.99).
product(ac1002, 'Gadget', 5.0).
product(ac1003, "Bolt", 0.25).
product(ac1004, `Nut`, 1.5e-1).

stock(ac1001, a1, 25).
stock(ac1002, a2, 3).
stock(ac1003, b1, 1_000).
stock(ac1004, b2, 0).

price(ac1001, 19.99).
price(ac1002, 5).
price(ac1003, 0.25).

%% ── Numbers and characters ──
number_demo([42, -7, 3.14, 1.0e10, 1.5E-3, 0xFF, 0o17, 0b1010, 0'a, 0'a, 0'\n, 0'''
            , 16'FF, 2'1010, 1.0Inf, 1.5NaN, 123456789012345678901234567890, 1r3]).

%% ── Atoms, strings and escapes ──
atoms([foo, 'Hello World', [], '[]', {}, '{}', ;, !, ',', '|', 'it''s', 'tab\there', 'uni\x41\code', 'a\
b', +, -, *, /, \+, =.., @>=, =@=, \==]).

%% ── Variables ──
vars(X, _Y, _, Result, _private, Long_Name1) :- X = Result, Long_Name1 = _private.

%% ── Rules ──
low_stock(Sku) :- stock(Sku, _, Qty), Qty < 10.

reorder(Sku, Amount) :-
    stock(Sku, _Bin, Qty),
    reorder_point(Sku, Point),
    Qty =< Point,
    Amount is Point * 2 - Qty.

reorder_point(Sku, 25) :- product(Sku, _, Price), Price >= 10, !.
reorder_point(_, 10).

total_value(Total) :-
    aggregate_all(sum(V), (stock(S, _, Q), price(S, P), V is Q * P), Total).

%% ── Control: conjunction, disjunction, if-then-else, negation, cut ──
classify(Qty, Label) :-
    (   Qty =:= 0 -> Label = out
    ;   Qty < 10  -> Label = low
    ;   Qty > 500 *-> Label = overstocked
    ;   Label = ok
    ).

available(Sku) :- \+ out_of_stock(Sku), \+ \+ product(Sku, _, _).
out_of_stock(Sku) :- stock(Sku, _, 0), !, fail.
out_of_stock(_) :- true ; false.

%% ── Operators and arithmetic ──
math(X, Y) :-
    A is X + Y, B is X - Y, C is X * Y, D is X / Y, E is X // Y, F is X mod Y, G is X rem Y,
    H is X ** 2, I is X ^ 2, J is abs(X), K is max(X, Y), L is min(X, Y), M is sqrt(X),
    N is X >> 1, O is X << 1, P is X /\ Y, Q is X \/ Y, R is X xor Y, S is \ X,
    T is truncate(3.7), U is cot(1.0), V is pi, W is e, Z is random(10),
    A =\= B, C \= D, E == F, G \== H, I @< J, K @=< L, M @> N, O @>= P,
    X = Y, X =.. [foo|Args], functor(X, Name, Arity), arg(1, X, A1), copy_term(X, Y),
    atom(Name), number(Arity), var(A1), nonvar(Args), is_list(Args), compound(X), integer(1).

%% ── Lists and recursion ──
sum_list_([], 0).
sum_list_([H|T], Sum) :- sum_list_(T, Rest), Sum is H + Rest.

first_two([A, B|_], A, B).
nth_stock(N, Sku) :- findall(S, stock(S, _, _), L), nth1(N, L, Sku).

quantities(Qs) :- findall(Q, stock(_, _, Q), Qs).
by_bin(Bins) :- bagof(S-Q, stock(S, B, Q), Bins), B = _.
all_skus(Skus) :- setof(S, B^Q^stock(S, B, Q), Skus).

%% ── Higher-order ──
doubled(In, Out) :- maplist([X, Y]>>(Y is X * 2), In, Out).
only_low(In, Out) :- include([Q]>>(Q < 10), In, Out).
total(In, Sum) :- foldl([X, A0, A]>>(A is A0 + X), In, 0, Sum).
call_it(G) :- call(G), once(G), ignore(G), forall(member(X, [1, 2]), X > 0).

%% ── Definite clause grammars ──
sku(Sku) --> letters(Ls), digits(Ds), { append(Ls, Ds, Cs), atom_codes(Sku, Cs) }.
letters([L|Ls]) --> [L], { code_type(L, alpha) }, !, letters(Ls).
letters([]) --> [].
order_line(Sku, Qty) --> sku(Sku), " x ", integer(Qty), blanks, ( "units" ; "pcs" ), eos.
greeting --> [hello], name.
name --> [world] | [prolog].
pushback, [a] --> [b].

%% ── Assert / retract and exceptions ──
restock(Sku, Amount) :-
    (   retract(stock(Sku, Bin, Old))
    ->  New is Old + Amount, assertz(stock(Sku, Bin, New))
    ;   throw(error(existence_error(sku, Sku), restock/2))
    ).

safe_restock(Sku, Amount) :-
    catch(restock(Sku, Amount),
          error(existence_error(_, S), _),
          ( format("unknown sku ~w~n", [S]), fail )).

%% ── Format and I/O ──
report :-
    forall(stock(S, B, Q),
           format("~w~t~12|~a~t~8+~d~n", [S, B, Q])),
    format("Total: ~2f ~s ~q ~p ~e ~g ~c~n", [12.5, "ok", 'A b', x, 1.0, 2.0, 65]),
    write_canonical([a, 'B']), print(done), nl,
    writeq('hello world'), write_term(f(X, Y), [quoted(true)]), put_char(a), tab(2).

main :-
    report,
    ( total_value(T) -> format("~2f~n", [T]) ; true ),
    halt.

%% ── Operators declared above ──
a ===> b.
check :- X = 2^^3^^4, Y = # 5, write(X-Y).

% ?- reorder(ac1002, N).   % N = 17
% ?- forall(low_stock(S), (write(S), nl)).

%% ── SWI-Prolog 7+ extensions: strings, dicts, functional notation ──
:- set_prolog_flag(double_quotes, string).
:- use_module(library(dicts)).
:- use_module(library(clpfd)).
:- use_module(library(yall)).
:- use_module(library(assoc)).
:- use_module(library(solution_sequences)).
:- use_module(library(strings)).
:- use_module(library(dcg/high_order)).
:- use_module(library(error)).
:- use_module(library(debug)).
:- use_module(library(option)).
:- use_module(library(pairs)).
:- use_module(library(persistency)).
:- use_module(library(thread)).
:- use_module(library(http/json)).

strings_demo(S) :-
    S = "a string",
    string_concat("abc", "def", C), string_length(C, _),
    sub_string(C, 0, 3, _, Sub), string_upper(Sub, _),
    split_string("a,b,c", ",", " ", Parts), atomic_list_concat(Parts, '-', _),
    string_codes(S, _), text_concat(abc, "def", _), term_string(_, "foo(bar)"),
    format(atom(_), "~w-~w", [a, b]), with_output_to(string(_), write(x)).

dicts_demo(D) :-
    D = point{x: 1, y: 2},
    X = D.x,
    D2 = D.put(z, 3),
    D3 = D2.put(_{w: 4}),
    get_dict(x, D, X), dict_pairs(D, Tag, Pairs), dict_create(_, Tag, Pairs),
    Y = D.get(y, 0), _ = D3.w, _ = Y,
    _{a: 1, b: "two", c: [1, 2, 3]} :< _{a: 1, b: "two", c: [1, 2, 3], d: 4}.

M.double() := R :- R is M.value * 2.
M.value() := M.get(value).

%% ── CLP(FD) and constraint operators ──
puzzle([S, E, N, D, M, O, R, Y]) :-
    Vars = [S, E, N, D, M, O, R, Y],
    Vars ins 0..9, all_different(Vars),
    S * 1000 + E * 100 + N * 10 + D + M * 1000 + O * 100 + R * 10 + E #=
    M * 10000 + O * 1000 + N * 100 + E * 10 + Y,
    M #\= 0, S #\= 0,
    X #> 3, X #< 10, X #>= 4, X #=< 9, X #\= 5, X in 1..5 \/ 7..9, Z #<==> (X #> 5), Z #==> A, A #\/ B, #\ C,
    sum(Vars, #=, _), label(Vars), labeling([ff, bisect], Vars), tuples_in([[X, Y]], [[1, 2]]),
    B in inf..sup, C in 0..sup, X #= abs(Y) + max(A, B) - min(A, C) * (X mod 3) // 2.

%% ── Tabling, determinism and declarations ──
:- table fib/2.
:- table path(_, _), conn(_, min), shortest(_, _, lattice(shorter/3)).
:- table (a/0, b/0) as subsumptive.
:- det(only_one/1).
:- multifile user:portray/1.
:- meta_predicate with_goal(0, ?), apply_to(2, ?, ?).
:- module_transparent helper/0.
:- thread_local seen/1.
:- volatile cache/2.
:- create_prolog_flag(my_flag, true, [type(boolean)]).
:- license(mit).
:- encoding(utf8).
:- predicate_options(show/2, 2, [indent(integer)]).
:- public hook/1.
:- noprofile(hook/1).

fib(0, 0).
fib(1, 1).
fib(N, F) :- N > 1, N1 is N - 1, N2 is N - 2, fib(N1, F1), fib(N2, F2), F is F1 + F2.
only_one(X) :- X = 1.
with_goal(G, _) :- call(G).
apply_to(P, X, Y) :- call(P, X, Y).
shorter(A, B, C) :- C is min(A, B).

%% ── Exceptions, cleanup, global variables ──
cleanup_demo :-
    setup_call_cleanup(open('f.txt', read, S), read_term(S, _, []), close(S)),
    catch_with_backtrace(foo, E, print_message(error, E)),
    call_cleanup(true, true),
    b_setval(v, 1), b_getval(v, _), nb_setval(k, 2), nb_getval(k, _),
    must_be(positive_integer, 3), is_of_type(atom, a), domain_error(x, y).
foo.

%% ── Special syntax: escapes, character codes, curly terms, operators as atoms ──
syntax_zoo :-
    A = 'quoted atom with \'escapes\' \x41\ é \U0001F4E6 \101\ \e \0\ \a \b \f \v',
    B = "string with ~w and \"quotes\"",
    C = `back quoted codes`,
    D = 0'c, E = 0' , F = 0''', G = 0'\\, H = 0'\x41\,
    I = 'multi\
line',
    J = [1, 2|T], K = '$VAR'(1), L = {a, b, c}, M = '{}'(x), N = [](x),
    O = (a :- b, c ; d -> e), P = (:- dynamic foo/1), Q = \+ a, R = - (1), S = -(-(1)), U = 1 - -1,
    V = a:b:c, W = f(;), X = (a , b), Y = [a|[b|[c|[]]]], Z = "",
    1 =:= 1.0, 1 =\= 2, a @< b, f(x) == f(x), X \== Y, X \= Y, X = Y, X \=@= Y, 1 is 2 - 1,
    atom_to_term('foo(X, Y)', _, _), read_term_from_atom('bar(Z)', _, []),
    char_code(Ch, 0'a), atom_chars(Ch, _),
    between(1, inf, _), succ(_, 3), plus(1, 2, _), nb_current(k, _),
    format(user_error, "err~n", []), print_message(informational, format("x", [])),
    Tail = T, Dummy = [A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, U, V, W, X, Y, Z, Tail, Dummy].

%% ── Higher-order: yall lambdas in every form ──
lambda_forms :-
    maplist([X]>>(X > 0), [1, 2]),
    maplist(\X^(X > 0), [1, 2]),
    maplist([X, Y]>>atom_length(X, Y), [a, bb], _),
    foldl({Z}/[X, A0, A]>>(A is A0 + X * Z), [1, 2], 0, _),
    aggregate_all(count, member(_, [a]), _), aggregate_all(max(X), member(X, [1, 2]), _),
    aggregate_all(bag(X), member(X, [1]), _), aggregate(count, X^member(X, [1]), _),
    findall(X-Y, (member(X, [1]), member(Y, [2])), _), findnsols(2, X, member(X, [1, 2, 3]), _),
    limit(2, member(_, [1, 2, 3])), offset(1, member(_, [1, 2])), order_by([asc(X)], member(X, [2, 1])), distinct(X, member(X, [1, 1])),
    forall(member(X, [1]), X > 0), \+ fail.

%% ── More DCG forms ──
digits([D|T]) --> digit(D), digits(T).
digits([D]) --> digit(D).
digit(D) --> [D], { code_type(D, digit) }.
ws --> [C], { code_type(C, space) }, !, ws.
ws --> [].
expr(X) --> term(X0), expr_rest(X0, X).
expr_rest(Acc, X) --> "+", !, term(Y), { Acc1 is Acc + Y }, expr_rest(Acc1, X).
expr_rest(X, X) --> [].
term(N) --> number(N).
call_dcg --> call(foo_dcg, x), \+ [y], phrase(ws), string_without(`,`, _), sequence(digit, ",", _), "literal", `codes`, [].
foo_dcg(_) --> [].
phrase_demo :- phrase(expr(V), `1+2`, Rest), phrase(ws, Rest), V == 3.

%% ── Modules, qualified goals, conditional compilation ──
qualified :- lists:append([1], [2], _), user:foo, Mod:Goal = lists:reverse([1], _), call(Mod:Goal), @(foo, user).
:- initialization((write(hi), nl)).
:- if(current_prolog_flag(bounded, false)).
big(X) :- X is 2 ** 100.
:- elif(true).
big(0).
:- else.
big(1).
:- endif.
