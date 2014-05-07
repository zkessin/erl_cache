-module(erl_cache_tests).
-include_lib("proper/include/proper.hrl").
-include_lib("eunit/include/eunit.hrl").
-compile(export_all).

keys() ->
    [
     <<"AAAAA">>,
     <<"8BFE5E9B-A5D6-4510-817C-60AD87C3A72B">>,
     <<"59665E9E-36E7-47FB-B8B6-4ECD569F06C5">>,
     <<"D54BA0D0-3D1C-4E9F-B098-D28433CB9EFF">>,
     <<"3A1D3C2A-AD51-4EFE-B690-75F16F59635C">>,
     <<"DB203B97-A7CE-40D3-9CD1-0F866EA9314C">>,
     <<"EB77972F-E98B-4161-9E2B-C951E4B04C2D">>,
     <<"7445F8E0-7B9E-49D8-B1E3-0D7F90ED0235">>,
     <<"73547A12-CD44-4706-9DF0-C56F9AF886AC">>,
     <<"3820D3E8-BFDA-4E62-A4BA-CC1C812832C5">>,
     <<"6EABF346-ED95-4D5D-9B04-D674E0BD1812">>,
     <<"EB75CC5E-06EB-43CD-9893-ECCDC759F09B">>,
     <<"BA7F285E-197A-4A5F-B379-2DE70034E61E">>,
     <<"9882CB8F-4E82-44A0-AEDC-EAEBA2C2CB8B">>,
     <<"EA05A25E-216B-4BFD-963D-13FB1BF82E94">>,
     <<"C125074F-EA4F-48F9-A8ED-1E563EEE9AD3">>,
     <<"EC10B758-7E81-4D41-8F07-D2D98C6C317D">>,
     <<"54BB4C80-610F-43B3-B55D-EA1A298B7FDD">>,
     <<"537E16D9-2C06-4CA5-82E4-C7C0F224385F">>,
     <<"5B054DAF-BE34-461F-92CD-1049507B43E7">>,
     <<"9DAD3ACB-DB1D-405B-B266-DEB32450176E">>,
     <<"0EF237C5-AE8D-4C63-BF3E-28999EC6317E">>,
     <<"6163DB63-15AA-4433-B4F7-E2FFB559267B">>,
     <<"BB1DC3FF-D322-40A8-9101-7C140A0508D3">>,
     <<"7EBF9397-D95E-465D-B9FE-692640CC95F9">>,
     <<"49E73B8C-EEFB-4F27-BC25-343ED9285464">>].

event() ->
    oneof([{get, oneof(keys())}%,
          % {set, oneof(keys()), int()}
          ]).

flatten(V) ->
    binary_to_list(iolist_to_binary(V)).

to_list(X) when is_binary(X) ->
    binary_to_list(X);
to_list(X) ->
    X.

set(Erlog, Key, Value)  ->
    PLCmd = flatten(io_lib:format("add_to_model(~p, ~p). ",[to_list(Key), Value])), 
    ?debugVal(PLCmd),
    {succeed, _} = erlog:prove(Erlog, PLCmd),
    {ok, Value}.


get(Erlog, Key) ->
    PLCmd = flatten(io_lib:format("model(~p, Y). ",[to_list(Key)])), 
    ?debugVal(PLCmd),
    PR = erlog:prove(Erlog, PLCmd) ,
    ?debugVal(PR),
    case  PR of
        {succeed, [{'Y', {Value}}]} ->
            {ok, Value};
        fail ->
            not_found
    end.


prop_cache_even() ->
    ?FORALL(Events,
            non_empty(list(event())),
            begin
                {ok,Erlog} = erlog:start_link(),
                ok = erlog:consult(Erlog, "../test/erl_cache_model.pl"),
                erl_cache:start_link(),

                R  = lists:all(fun({get, Key}) ->
                                       CV = erl_cache:get(Key),
                                       MV = get(Erlog, Key),
                                       ?debugVal(Key),
                                       ?debugVal(CV),
                                       ?debugVal(MV),
                                       MV =:= CV;
                                     
                             ({set, Key, Value}) ->
                                      erl_cache:set(Key,Value),
                                      set(Erlog, Key,Value),
                                      true
                             end, Events),
                erlog:halt(Erlog),
                R
            end).

run_test() ->
    ?assert(proper:quickcheck(prop_cache_even(), 
                              [{to_file, user}])),
    ok.
