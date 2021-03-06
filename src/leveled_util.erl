%% -------- Utility Functions ---------
%%
%% Generally helpful funtions within leveled
%%

-module(leveled_util).


-include("include/leveled.hrl").

-include_lib("eunit/include/eunit.hrl").


-export([generate_uuid/0,
            integer_now/0,
            integer_time/1,
            magic_hash/1]).


-spec generate_uuid() -> list().
%% @doc
%% Generate a new globally unique ID as a string.
%% Credit to
%% https://github.com/afiskon/erlang-uuid-v4/blob/master/src/uuid.erl
generate_uuid() ->
    <<A:32, B:16, C:16, D:16, E:48>> = leveled_rand:rand_bytes(16),
    L = io_lib:format("~8.16.0b-~4.16.0b-4~3.16.0b-~4.16.0b-~12.16.0b", 
                        [A, B, C band 16#0fff, D band 16#3fff bor 16#8000, E]),
    binary_to_list(list_to_binary(L)).

-spec integer_now() -> non_neg_integer().
%% @doc
%% Return now in gregorian seconds
integer_now() ->
    integer_time(os:timestamp()).

-spec integer_time (erlang:timestamp()) -> non_neg_integer().
%% @doc
%% Return a given time in gergorian seconds
integer_time(TS) ->
    DT = calendar:now_to_universal_time(TS),
    calendar:datetime_to_gregorian_seconds(DT).


-spec magic_hash(any()) -> integer().
%% @doc 
%% Use DJ Bernstein magic hash function. Note, this is more expensive than
%% phash2 but provides a much more balanced result.
%%
%% Hash function contains mysterious constants, some explanation here as to
%% what they are -
%% http://stackoverflow.com/questions/10696223/reason-for-5381-number-in-djb-hash-function
magic_hash({binary, BinaryKey}) ->
    H = 5381,
    hash1(H, BinaryKey) band 16#FFFFFFFF;
magic_hash(AnyKey) ->
    BK = term_to_binary(AnyKey),
    magic_hash({binary, BK}).

hash1(H, <<>>) -> 
    H;
hash1(H, <<B:8/integer, Rest/bytes>>) ->
    H1 = H * 33,
    H2 = H1 bxor B,
    hash1(H2, Rest).




%%%============================================================================
%%% Test
%%%============================================================================

-ifdef(TEST).


magichashperf_test() ->
    KeyFun =
        fun(X) ->
            K = {o, "Bucket", "Key" ++ integer_to_list(X), null},
            {K, X}
        end,
    KL = lists:map(KeyFun, lists:seq(1, 1000)),
    {TimeMH, _HL1} = timer:tc(lists, map, [fun(K) -> magic_hash(K) end, KL]),
    io:format(user, "1000 keys magic hashed in ~w microseconds~n", [TimeMH]),
    {TimePH, _Hl2} = timer:tc(lists, map, [fun(K) -> erlang:phash2(K) end, KL]),
    io:format(user, "1000 keys phash2 hashed in ~w microseconds~n", [TimePH]),
    {TimeMH2, _HL1} = timer:tc(lists, map, [fun(K) -> magic_hash(K) end, KL]),
    io:format(user, "1000 keys magic hashed in ~w microseconds~n", [TimeMH2]).

-endif.