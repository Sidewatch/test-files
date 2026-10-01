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
