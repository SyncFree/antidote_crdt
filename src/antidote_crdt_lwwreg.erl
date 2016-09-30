%% -------------------------------------------------------------------
%%
%% Copyright (c) 2014 SyncFree Consortium.  All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------

%% @doc module antidote_crdt_lwwreg - An operation based last-writer-wins register
%% Each operation is assigned a timestamp, which is guaranteed to be greater than
%% the current timestamp.
%% The current value of the register is the value assigned with the greatest timestamp
%% or the empty binary if there was no assignment yet.

-module(antidote_crdt_lwwreg).

-behaviour(antidote_crdt).

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.

-export([ new/0,
          value/1,
          downstream/2,
          update/2,
          equal/2,
          to_binary/1,
          from_binary/1,
          is_operation/1,
          require_state_downstream/1
        ]).

-export_type([lwwreg/0, lwwreg_op/0]).

-opaque lwwreg() :: {non_neg_integer(), term()}.

-type lwwreg_op() :: {assign, term(), non_neg_integer()}  | {assign, term()}.

new() ->
  {0, <<>>}.

value({_Time, Val}) ->
    Val.

-spec downstream(lwwreg_op(), lwwreg()) -> {ok, term()}.
downstream({assign, Value, Time}, {OldTime, _OldValue}) ->
  {ok, {max(Time, OldTime+1), Value}};
downstream({assign, Value}, State) ->
  downstream({assign, Value, make_micro_epoch()}, State).

make_micro_epoch() ->
    {Mega, Sec, Micro} = os:timestamp(),
    (Mega * 1000000 + Sec) * 1000000 + Micro.


update(Effect, State) ->
  % take the state with maximum time, if times are equal use maximum state
  {ok, max(Effect, State)}.


require_state_downstream(_Operation) -> true.

is_operation({assign, _Value}) -> true;
is_operation(_Other) -> false.


equal(CRDT1, CRDT2) ->
    CRDT1 == CRDT2.

to_binary(CRDT) ->
    erlang:term_to_binary(CRDT).

from_binary(Bin) ->
    erlang:binary_to_term(Bin).

-ifdef(test).
all_test() ->
    S0 = new(),
    {ok, Downstream} = downstream({assign, a}, S0),
    {ok, S1} = update(Downstream, S0),
    ?assertEqual(a, value(S1)).

-endif.
