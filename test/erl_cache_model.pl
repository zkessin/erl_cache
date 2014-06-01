%-*-Prolog -*-

model("KEY","value").
 

add_to_model(Key, Value) :-
    retract(model(Key, _)),
    asserta(model(Key, Value)).
