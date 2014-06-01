-module(erl_cache_tests).
-include_lib("proper/include/proper.hrl").
-include_lib("eunit/include/eunit.hrl").
-compile(export_all).

keys() ->
    [
     "AAAAAAAA",
     "8BFE5E9B",
     "59665E9E",
     "D54BA0D0",
     "3A1D3C2A",
     "DB203B97",
     "EB77972F",
     "7445F8E0",
     "73547A12",
     "3820D3E8",
     "6EABF346",
     "EB75CC5E",
     "BA7F285E",
     "9882CB8F",
     "EA05A25E",
     "C125074F",
     "EC10B758",
     "54BB4C80",
     "537E16D9"].


event() ->
    oneof([{get, oneof(keys())}
          ,{set, oneof(keys()), int()}
          ]).





set(Erlog, Key, Value)  ->
    case erlog:prove(Erlog, {asserta,{model,Key,Value}}) of
        {succeed, _} ->
            true;
        _R ->
            false
    end.

get(Erlog, Key) ->
    PR = erlog:prove(Erlog, {model, Key, {'Y'}}) ,
    case  PR of
        {succeed, [{'Y', Value}]} ->
            {ok, Value};
        fail ->
            not_found
    end.

run([], _Erlog) ->
    true;
run([C|Rest], Erlog) ->
    case run1(C, Erlog) of
        true ->
            run(Rest,Erlog);
        false ->
            false
    end.

run1({get, Key}, Erlog) ->
    CV = erl_cache:get(Key),
    MV = get(Erlog, Key),
    MV =:= CV;    
run1({set, Key, Value}, Erlog) ->
    erl_cache:set(Key,Value),
    set(Erlog, Key,Value).
    

prop_cache_even() ->
    {ok,EC}    = erl_cache:start_link(),
    ?FORALL(Events,
            non_empty(list(event())),
            begin
                {ok,Erlog} = erlog:start_link(),
                ok         = erlog:consult(Erlog, "../test/erl_cache_model.pl"),

                R = run(Events, Erlog),
                erlog:halt(Erlog),
                gen_server:cast(EC, reset),
                R
            end).

run_test() ->
    ?assert(proper:quickcheck(prop_cache_even(), 
                              [{to_file, user},200])),
    ok.
