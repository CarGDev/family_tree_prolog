% Simple family tree for families
female(fabiola). female(zahra). female(maya). female(lenny). female(demi). female(lesly). female(urvi). female(tenisha). female(penny). female(autum). female(lauri). female(patty). female(tricia). female(karen). female(simone). female(leigh). female(patrice). female(duff). female(lenascuas). female(hilary). female(megan).

male(cosmo). male(carlos). male(gabriel). male(gannie). male(stevie). male(shubam). male(bryan). male(lemuel). male(barron). male(agustin). male(dene). male(enos). male(ken). male(rusty). male(zach). male(klement). male(sean). male(donnell). male(jacob). male(rossell). male(jermia). male(lj).

person(P) :- male(P).
person(P) :- female(P).

parent(carlos, cosmo). parent(fabiola, cosmo).
parent(carlos, maya). parent(fabiola, maya).
parent(carlos, stevie). parent(fabiola, stevie).
parent(gabriel, lenny). parent(demi, lenny).
parent(gabriel, bryan). parent(demi, bryan).
parent(gannie, lesly). parent(zahra, lesly).
parent(gannie, lemuel). parent(zahra, lemuel).
parent(lj, ken). parent(lenascuas, ken).
parent(lj, jermia). parent(lenascuas, jermia).
parent(lj, rossell). parent(lenascuas, hilary).
parent(shubam, penny). parent(urvi, penny).
parent(shubam, rusty). parent(urvi, rusty).
parent(cosmo, barron). parent(lenny, barron).
parent(cosmo, tenisha). parent(lenny, tenisha).
parent(cosmo, agustin). parent(lenny, agustin).
parent(lemuel, dene). parent(maya, dene).
parent(lemuel, lauri). parent(maya, lauri).
parent(bryan, enos). parent(lesly, enos).
parent(stevie, zach). parent(penny, zach).
parent(stevie, patty). parent(penny, patty).
parent(rusty, sean). parent(autum, sean).
parent(rusty, leigh). parent(autum, leigh).
parent(barron, klement). parent(leigh, klement).
parent(barron, tricia). parent(leigh, tricia).
parent(dene, karen). parent(simone, karen).
parent(enos, donnell). parent(patty, donnell).
parent(enos, patrice). parent(patty, patrice).
parent(zach, jacob). parent(duff, jacob).
parent(lesly, megan). parent(bryan, megan).
parent(jermia, duff). parent(rossell, duff).
parent(sean, simone). parent(lauri, simone).

married(carlos, fabiola).
married(gabriel, demi).
married(gannie, zahra).
married(lj, lenascuas).
married(shubam, urvi).
married(cosmo, lenny).
married(lemuel, maya).
married(bryan, lesly).
married(stevie, penny).
married(rusty, autum).
married(barron, leigh).
married(dene, simone).
married(enos, patty).
married(zach, duff).
married(jermia, rossell).
married(sean, lauri).


sibling(X, Y) :- parent(P, X), parent(P, Y), X \= Y.
brother(X, Y) :- sibling(X, Y), male(X).
sister(X, Y) :- sibling(X, Y), female(X).
father(F, C) :- parent(F, C), male(F).
mother(M, C) :- parent(M, C), female(M).
child(C, P) :- parent(P, C).
grandparent(G, C) :- parent(G, P), parent(P, C).
greatgrandparent(E, C) :- parent(E, P), grandparent(P, C).
descendant(D, A) :- parent(A, D).
descendant(D, A) :- parent(P, D), descendant(P, A).
grandchild(C, G) :- grandparent(G, C).
ancestor(A, D) :- parent(A, D).
ancestor(A, D) :- parent(P, D), ancestor(A, P).
uncle(U, N) :- male(U), sibling(U, P), parent(P, N).
aunt(U, N) :- female(U), sibling(U, P), parent(P, N).
cousin(A, B) :- parent(P1, A), parent(P2, B), sibling(P1, P2).
niece(N, X) :- female(N), parent(P, N), sibling(P, X).
nephew(N, X) :- male(N), parent(P, N), sibling(P, X).
secondcousin(A, B) :- parent(P1, A), parent(P2, B), cousin(P1, P2).
cousin_removed(A, B) :- parent(P, A), cousin(P, B).
cousin_removed(A, B) :- parent(P, B), cousin(P, A).
spouse(X, Y) :- married(X, Y).
spouse(X, Y) :- married(Y, X).
spouse(X, Y) :- parent(X, C), parent(Y, C), X \= Y.
husband(H, W) :- spouse(H, W), male(H).
wife(W, H) :- spouse(W, H), female(W).

% Adding a function that helps with relations
report(Label, Rel) :-
    format("~n== ~w ==~n", [Label]),
    forall(person(P),
           (findall(X, call(Rel, X, P), Xs0),
            sort(Xs0, Xs),
            (Xs \= []
            -> format("~w: ~w~n", [P, Xs])
            ; true
            ))).

couples :-
    setof(X-Y, (spouse(X, Y), X @< Y), L),
    forall(member(A-B, L), format("~w & ~w~n", [A, B])).

dot :-
    format("digraph family {~n  node [style=filled];~n"),
    forall(male(P), format("  ~w [fillcolor=lightblue];~n", [P])),
    forall(female(P), format("  ~w [fillcolor=pink];~n", [P])),
    forall(married(A, B), format("  ~w -> ~w [dir=none, style=dashed];~n", [A, B])),
    forall(parent(P, C), format("  ~w -> ~w;~n", [P, C])),
    format("}~n").

% Generation 0 = people with no known parents (a parentless spouse joins their partner's row)
% A couple always shares the deeper of their two rows, so rank=same sets never conflict.
base_generation(P, G) :-
    parent(_, P), !,
    findall(PG, (parent(X, P), generation(X, PG)), L),
    max_list(L, M), G is M + 1.
base_generation(_, 0).

generation(P, G) :-
    base_generation(P, B),
    findall(SB, (spouse(P, S), base_generation(S, SB)), L),
    max_list([B|L], G).

% Classic family-chart layout (square lines):
%   each couple is ONE joined box, so spouses always stay side by side;
%   a vertical drop from the middle of the couple reaches a horizontal bar;
%   each child hangs from that bar. One bar per set of parents.
parents_of(C, Ps) :- setof(P, parent(P, C), Ps).

family_units(Units) :-
    findall(Ps-C, (person(C), parents_of(C, Ps)), Pairs),
    keysort(Pairs, Sorted),
    group_pairs_by_key(Sorted, Units).

% Graph node that draws person P: their couple box, or P alone when unmarried.
node_id(P, Id) :-
    once(spouse(P, S)), !,
    ( P @< S -> format(atom(Id), "c_~w_~w", [P, S])
    ; format(atom(Id), "c_~w_~w", [S, P]) ).
node_id(P, P).

% Two parents: drop from the couple box's centre. One parent: drop from that person's own cell.
anchor([P], A) :- !,
    node_id(P, Id),
    ( sub_atom(Id, 0, _, _, c_) -> format(atom(A), "~w:~w:s", [Id, P]) ; A = Id ).
anchor([P|_], A) :-
    node_id(P, Id),
    format(atom(A), "~w:s", [Id]).

% Line target for P: their own cell inside the couple box, or the plain node.
node_port(P, Ref) :-
    node_id(P, Id),
    ( sub_atom(Id, 0, _, _, c_) -> format(atom(Ref), "~w:~w:n", [Id, P]) ; Ref = Id ).

fill_color(P, lightblue) :- male(P), !.
fill_color(_, pink).

couple_node(X, Y) :-
    fill_color(X, CX), fill_color(Y, CY),
    format("  c_~w_~w [shape=plaintext, style=\"\", label=<<TABLE BORDER=\"0\" CELLBORDER=\"1\" CELLSPACING=\"0\" CELLPADDING=\"6\"><TR><TD PORT=\"~w\" BGCOLOR=\"~w\">~w</TD><TD PORT=\"~w\" BGCOLOR=\"~w\">~w</TD></TR></TABLE>>];~n",
           [X, Y, X, CX, X, Y, CY, Y]).

unit(N, Ps, Cs) :-
    anchor(Ps, A),
    format(atom(D), "d_~w", [N]),
    format("  ~w [shape=point, width=0.03, label=\"\"];~n  ~w -> ~w [weight=100];~n", [D, A, D]),
    forall(member(C, Cs),
           ( node_port(C, Ref), format("  ~w -> ~w [weight=50];~n", [D, Ref]) )).

tree :-
    setof(X-Y, (spouse(X, Y), X @< Y), Couples),
    family_units(Units),
    findall(G, (person(P), generation(P, G)), Gs),
    max_list(Gs, Max),
    format("digraph family {~n  rankdir=TB;~n  splines=true;~n  nodesep=0.3;~n  ranksep=0.6;~n  newrank=true;~n"),
    format("  node [shape=box, style=\"filled,rounded\"];~n  edge [dir=none, penwidth=1.4];~n"),
    forall(( person(P), \+ spouse(P, _) ),
           ( fill_color(P, C), format("  ~w [fillcolor=~w];~n", [P, C]) )),
    forall(member(X-Y, Couples), couple_node(X, Y)),
    forall(nth1(N, Units, Ps-Cs), unit(N, Ps, Cs)),
    forall(between(0, Max, G),
           ( N is G + 1,
             format("  g~w [label=\"Generation ~w\", shape=plaintext, style=\"\"];~n", [G, N]),
             findall(Id, (person(P), generation(P, G), node_id(P, Id)), Ids0),
             sort(Ids0, Ids),
             ( Ids = [] -> true
             ; atomic_list_concat(Ids, '; ', S),
               format("  {rank=same; g~w; ~w;}~n", [G, S]) ) )),
    forall(between(1, Max, G),
           ( F is G - 1, format("  g~w -> g~w [style=invis, minlen=2];~n", [F, G]) )),
    format("}~n").

run(dot)      :- dot.
run(tree)     :- tree.
run(couples)  :- couples.
run(show_all) :- show_all.

command(Cmd) :-
    current_prolog_flag(argv, Args),
    member(Cmd, Args),
    memberchk(Cmd, [dot, tree, couples, show_all]), !.

cli :- command(Cmd), run(Cmd).

% Run a command and exit only when one is given on the command line;
% plain `swipl family_tree.pl` stays in the interactive prompt.
:- if(command(_)).
:- initialization(cli, main).
:- endif.

show_all :-
    report("Parents", parent),
    report("Siblings", sibling),
    report("Grandparents", grandparent),
    report("Great-grandparents", greatgrandparent),
    report("Ancestors", ancestor),
    report("Uncles", uncle),
    report("Aunts", aunt),
    report("Cousins", cousin),
    report("Descendants", descendant),
    report("Second cousins", secondcousin),
    report("Nieces", niece),
    report("Nephews", nephew).
