%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Zmienne:
% State  		stan
% Goals 		lista celów
% InitState 	stan początkowy
% Plan 			skonstruowany plan
% FinalState 	stan końcowy
% Goal 			cel wybrany z listy celów
% RestGoals 	pozostałe cele
% Action 		akcja osiągająca zadany cel
% CondGoals		warunki dla akcji, które stają się nowymi celami
% PrePlan		skonstruowany preplan
% State1		stan pośredni 1, osiągany po wykonaniu preplanu
% InstAction	akcja ukonkretniona przed wykonaniem
% State2 		stan pośredni 2, osiągany po wykonaniu akcji w stanie pośrednim 1
% PostPlan		skonstruowany postplan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Procedury opisujące wykonanie programu.
% 
% Działanie w rekurencji
% wymaga dodatkowego argumentu wejściowego
% w śledzonej procedurze określający aktualny
% poziom rekurencji.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Procedura bez sprawdzania rekurencji
% Wariant 1: w celu wyprowadzenia wartości zmiennych
% na wejściu do procedury
log(1, ProcName, Clause, ArgList) :-
    nl, write('WEJŚCIE'),
	nl, write(ProcName),
	write(' typ: '), write(Clause),
	write_args(ArgList), nl, read(_).

% Wariant 2: w celu wyprowadzenia wartości zmiennych
% na zakończenie procedury
log(2, ProcName, Clause, ArgList) :-
	nl, write('WYJŚCIE'),
    nl, write(ProcName),
	write(' typ: '), write(Clause),
	write_args(ArgList), nl.

% Wariant 3: w celu wyprowadzenia wartości zmiennych
% wraz z informacją o zmianie typu procedury
log(3, ProcName, Clause, ArgList) :-
	nl, write('NIEPOWODZENIE'),
    nl, write(ProcName),
	write(' typ: '), write(Clause),
	write_args(ArgList), nl.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Procedura ze sprawdzaniem rekurencji
% Wariant 1: w celu wyprowadzenia wartości zmiennych
% na wejściu do procedury rekurencyjnej
rec_log(1, ProcName, Clause, Level, ArgList) :-
    nl, write('WEJŚCIE NA POZIOMIE '),write(Level),
	nl, write(ProcName),
    write(' typ: '), write(Clause),
	write_args(ArgList), nl, read(_).

% Wariant 2: w celu wyprowadzenia wartości zmiennych
% na zakończenie procedury na danym poziomie rekurencji
rec_log(2, ProcName, Clause, Level, ArgList) :-
	nl, write('WYJŚCIE NA POZIOMIE '),write(Level),
    nl, write(ProcName),
	write(' typ: '), write(Clause),
	write_args(ArgList), nl,
	end_log(Level, ProcName).

% Wariant 3: w celu wyprowadzenia wartości zmiennych
% wraz z informacją o zmianie typu procedury
% na danym poziomie rekurencji
rec_log(3, ProcName, Clause, Level, ArgList) :-
    nl,write('NIEPOWODZENIE NA POZIOMIE '),write(Level),
	nl, write(ProcName),
	write(' typ: '), write(Clause),
	write_args(ArgList), nl.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Dodatkowe procedury wspierające tworzenie logów

write_args([]).

write_args([First|Rest]) :-
	write_one_arg(First),
	write_args(Rest).

write_one_arg(Name/Val)  :-
	nl, write(Name), write('='), write(Val).

end_log(0, ProcName)  :-
	nl,  nl,  write('KONIEC ŚLEDZENIA  '), write(ProcName), nl, nl.

end_log(Level,_)  :-
	Level > 0,
	nl, read(_).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Wrappery potrzebne aby móc zwiększać limit

wrapper(InitState, Goals, Limit, Plan, FinalState) :-		% AchievedGoals? Nie potrzebne raczej
    log(1, 'Wrapper', 1, ['InitState'/InitState, 'Goals'/Goals, 'Limit'/Limit]),
	plan(InitState, Goals, [], Limit, Plan, FinalState, 0),
    log(2, 'Wrapper', 1, ['Plan'/Plan, 'Fin'/FinalState]).
    
wrapper(InitState, Goals, Limit, Plan, FinalState) :-
    log(3, 'Wrapper', 1, ['InitState'/InitState, 'Goals'/Goals, 'Limit'/Limit]),
    % Tutaj jakieś dodatkowe info, czy coś?
    NewLimit is Limit + 1,
    wrapper(InitState, Goals, NewLimit, Plan, FinalState).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Wariant 1 planu, który wykonuje procedurę 
% goals_achieved(Goals, State), gdy stan początkowy 
% jest równy stanowi finalnemu

plan(State, Goals, _, _, [], State, Level) :-
    rec_log(1, 'Plan', 1, Level, ['State'/State, 'Goals'/Goals]),
	goals_achieved(Goals, State),
    rec_log(2, 'Plan', 1, Level, ['State'/State, 'Goals'/Goals]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	
% Wariant 2 planu, który wykonuje określone akcje
% aby dojść do stanu finalnego.

plan(InitState, Goals, AchievedGoals, Limit, Plan, FinalState, Level) :-
    rec_log(3, 'Plan', 1, Level, ['State'/InitState, 'Goals'/Goals]),
	rec_log(1, 'Plan', 2, Level, ['State'/InitState, 'Goals'/Goals, 'AchievedGoals'/AchievedGoals]),
    
    Limit > 0,
    
    NewLevel is Level + 1,
    
    generate_limit_pre(LimitPre,0, Limit),
    
	choose_goal(Goal, Goals, RestGoals, InitState),

	achieves(Goal, Action),

	requires(Action, CondGoals),

	plan(InitState, CondGoals, AchievedGoals, LimitPre, PrePlan, State1, NewLevel),

	inst_action(Action, Goal, State1, InstAction),

    check_action(InstAction, AchievedGoals),
    
	perform_action(State1, InstAction, State2), !,

    LimitPost is Limit - LimitPre - 1,
    
	plan(State2, RestGoals, [Goal|AchievedGoals], LimitPost, PostPlan, FinalState, NewLevel),

	conc(PrePlan, [InstAction|PostPlan], Plan),
    
    rec_log(2, 'Plan', 2, Level, ['Limit'/Limit, 'Plan'/Plan, 'Fin'/FinalState]).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Wszystkie procedury, które nie są ściśle powiązane z innymi
% ale potrzebne są, aby procedury poprawnie działały
% 
generate_limit_pre(Limit, Limit, _).

generate_limit_pre(LimitPre, Limit, UpperLimit) :-
    NewLimit is Limit+1,
    NewLimit < UpperLimit,
	generate_limit_pre(LimitPre, NewLimit, UpperLimit).

check_action(move(X,Y,Z), AchievedGoals) :-
    \+part_of(on(X,Y), AchievedGoals),
    \+part_of(clear(Z), AchievedGoals).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Implementacja procedury standardowej member(X, Y).
part_of(Member, [Member|_]).

part_of(Member, [_|ListRest]) :-
	part_of(Member, ListRest).
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Procedura sprawdzająca, czy zmienna nie posiada
% dodatkowego warunku, który musi spełnić.

no_slash(X) :-
	var(X).
	
no_slash(X) :-
	X \= _/_.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Procedura sprawdzająca spełnienie celu w zadanym stanie.

goal_achieved(clear(X), State) :-
	no_slash(X),
	part_of(clear(X), State).
	
goal_achieved(clear(X/Cond), State) :-
	nonvar(Cond),
	goal_achieved(Cond, State),
	part_of(clear(X), State).
	
goal_achieved(on(X,Y), State) :-
	no_slash(X),
	no_slash(Y),
	part_of(on(X,Y), State).
	
goal_achieved(on(X/Cond, Y), State) :-
	no_slash(Y),
	nonvar(Cond),
	goal_achieved(Cond, State),
	part_of(on(X,Y), State).

goal_achieved(on(X, Y/Cond), State) :-
	no_slash(X),
	nonvar(Cond),
	goal_achieved(Cond, State),
	part_of(on(X,Y), State).
	
goal_achieved(on(X/Cond, Y/Cond2), State) :-
	nonvar(Cond),
	nonvar(Cond2),
	goal_achieved(Cond, State),
	goal_achieved(Cond2, State),
	part_of(on(X,Y), State).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Procedura usuwająca elementy z listy

remove([First|Rest], X, Rest) :-
	part_of(X, [First]).

remove([First|RestList], X, [First|Rest]) :-
	remove(RestList, X, Rest).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Procedura łącząca

conc([], X, X).

conc([Head|Tail], X, [Head|Tail2]) :-
	conc(Tail, X, Tail2).
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Procedura sprawdzająca, czy wszystkie cele z Goals
% są spełnione w State.
% Cele mogą być zarówno ukonkretnione, jak i nie.
% goals_achieved(Goals, State).

goals_achieved([], _).

goals_achieved([Goal|Rest], State) :-
	goal_achieved(Goal, State),
	goals_achieved(Rest, State).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Z listy Goals wybiera do przetwarzania cel (Goal), 
% który nie jest spełniony w aktualnym stanie (State).
% Pozostałe cele zapisuje do RestGoals.
% choose_goal(Goal, Goals, RestGoals, State).

choose_goal(Goal, [Goal|Rest], Rest, State) :-
    log(1, 'Choose_goal', 1, ['GoalList'/[Goal|Rest], 'State'/State]), 
	\+goal_achieved(Goal, State),
    log(2, 'Choose_goal', 1, ['Goal'/Goal, 'Rest'/Rest]). 
	
choose_goal(Goal, [X|RestGoals], [X|Rest], State) :-
    log(3, 'Choose_goal', 1, ['GoalList'/[X|RestGoals], 'State'/State]),
    log(1, 'Choose_goal', 2, ['GoalList'/[X|RestGoals], 'State'/State]),
	choose_goal(Goal, RestGoals, Rest, State),
	log(2, 'Choose_goal', 2, ['Goal'/Goal, 'Rest'/[X|Rest]]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Określa akcję (Action), która osiąga podany cel (Goal).
% Cel może być zarówno ukonkretniony, jak i nie.
% achieves(Goal, Action).

achieves(on(X, Y), move(X, Z/(on(X, Z)), Y)) :-
    log(1, 'Achieves', 1, ['Goal'/on(X, Y)]),
    log(2, 'Achieves', 1, ['Action'/move(X, Z/(on(X, Z)), Y)]).

achieves(clear(X), move(Y/on(Y, X), X, Z/clear(Z))) :-
    log(1, 'Achieves', 2, ['Goal'/clear(X)]),
    log(2, 'Achieves', 2, ['Action'/move(Y/on(Y, X), X, Z/clear(Z))]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Określa warunki (CondGoals) wykonania podanej akcji (Action),
% które stają się celami dla następnego kroku algorytmu.
% requires(Action, CondGoals).

requires(move(X, Y, Z), [clear(X), clear(Z)]) :-
    log(1, 'Requires', 1, ['Action'/move(X, Y, Z)]),
	no_slash(X),
    log(2, 'Requires', 1, ['CondGoals'/[clear(X), clear(Z)]]).
	
requires(move(X/C, Y, Z), [clear(X/C)]) :-
    log(3, 'Requires', 1, ['Action'/move(X, Y, Z)]),
    log(1, 'Requires', 2, ['Action'/move(X/C, Y, Z)]),
    log(2, 'Requires', 2, ['CondGoals'/[clear(X/C)]]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Y - klocek który przesuwamy
get_clear([],_, []).

get_clear([clear(X)|Rest], Y/_, [X|RestClear]):-
    X \= Y, !,
    get_clear(Rest, Y, RestClear).
    
get_clear([clear(X)|Rest], Y, [X|RestClear]):-
    no_slash(Y),
    X \= Y, !,
    get_clear(Rest, Y, RestClear).

get_clear([clear(_)|Rest], Y, Clear):-
    get_clear(Rest,Y,Clear).

get_clear([on(_,_)|Rest], Y, Clear):-
    get_clear(Rest, Y, Clear).

% Ukonkretnia akcję (Action) przed wykonaniem. 
% inst_action(Action, Goal, State, InstAction).

handle_input(State, X, UserInput, Clear):-
    get_clear(State, X, Clear),
    nl,nl, write('Gdzie chcesz przenieść klocek '),write(X),write('?'),nl,
	write('Wolne miejsca: '),write(Clear), nl,
    read(UserInput),
    process_input(State, X, UserInput, Clear).

process_input(_, _, Input, _):-
    Input \= 'nawrót'.

process_input(State, X, Input, Clear) :-
    Input \= 'nawrót',
	handle_input(State, X, Input, Clear).

inst_action(move(X, Y, Z), Cond, State, move(InstX, InstY, UserInput)) :-
    log(1, 'Inst_action', 1, ['Action'/move(X, Y, Z), 'Cond'/Cond, 'State'/State]),
	handle_input(State, X, UserInput, _),
    inst1(X, Cond, State, InstX, Rest), write(Rest),
	inst2(Y, Cond, State, InstY),
	nl,write('Utworzona akcja: move('), write(X), write(','), write(Y), write(','), write(UserInput),write(')'), nl,
    log(2, 'Inst_action', 1, ['InstAction'/move(InstX, InstY, UserInput)]).

inst_action(move(X, Y, _), Cond, State, move(InstX, InstY, UserInput)) :-
    nl, write('Nawrót'), nl,
    inst_action(move(X, Y, _), Cond, State, move(InstX, InstY, UserInput)),

%inst_action(move(X, Y, Z), Cond, State, move(InstX, InstY, InstZ)) :-
%   inst1(X, Cond, State, InstX, Rest),%
%	inst2(Y, Cond, State, InstY),
%	inst3(Z, Cond, Rest, InstZ).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Dla warunku on() - X ukonkretnione
inst1(X, on(X,_), _, X, _).

% Dla warunku clear() - 
% gdy zmienna jest ukonkretniona
inst1(X, clear(_), _, X, _) :-
	no_slash(X).

% jest struktura
inst1(X/Cond, clear(_), State, X, Rest) :-
	goal_achieved(Cond, State),
    remove(State, clear(X), Rest).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Dla warunku clear() - Y ukonkretnione
inst2(Y, clear(_), _, Y):-
	no_slash(Y).

% struktura
inst2(Y/Cond, clear(_), State, Y):-
	goal_achieved(Cond, State).

% Dla warunku on() - Y jest struktura
inst2(Y/Cond, on(_,_), State, Y) :-
	goal_achieved(Cond, State).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Wykorzystywane metody były pomocne jedynie
% gdy klient nie miał wpływu na wybór
%
% Dla warunku clear() -
% Z ukonkretnione
% inst3(Z, on(_,Z), _, Z).

% Z jest strukturą
% inst3(Z/Cond, clear(_), State, Z):-
%    goal_achieved(Cond, State).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Określa stan (State2) osiągany ze stanu (State1)
% podanego przez wykonanie podanej akcji (Action).
% perform_action(State1, Action, State2).

perform_action(State, move(X, Y, Z), [on(X,Z), clear(Y)|Rest]) :-
    log(1, 'Perform_action', 1, ['State'/State, 'Action'/move(X, Y, Z)]),
	part_of(clear(Z), State),
	part_of(on(X, Y), State),
	remove(State, clear(Z), RestState),
	remove(RestState, on(X, Y), Rest),
    log(2, 'Perform_action', 1, ['OutState'/[on(X,Z), clear(Y)|Rest]]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%