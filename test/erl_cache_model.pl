%-*-Prolog -*-

model(Key, Value).


clear_value(Key) :-
    retract(model(Key, _)).


add_to_model(Key, Value) :-
    retract(model(Key, _)),
    asserta(model(Key, Value)).


  
