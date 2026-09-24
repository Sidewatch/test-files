% Prolog: a small family database with rules and a recursive ancestor relation.
:- module(family, [ancestor/2, siblings/2]).

parent(ada, bob).
parent(ada, cara).
parent(bob, dan).
parent(dan, eve).

male(bob). male(dan).
female(ada). female(cara). female(eve).

% X is an ancestor of Y
ancestor(X, Y) :- parent(X, Y).
ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).

siblings(X, Y) :- parent(P, X), parent(P, Y), X \== Y.

grandmother(G, C) :- female(G), parent(G, P), parent(P, C).

count_descendants(X, N) :-
    findall(D, ancestor(X, D), Ds),
    length(Ds, N).

% ?- count_descendants(ada, N).   % N = 4
