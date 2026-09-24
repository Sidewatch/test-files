%% A supervised key-value store as a gen_server.
-module(sample).
-behaviour(gen_server).

-export([start_link/0, put/2, get/1]).
-export([init/1, handle_call/3, handle_cast/2]).

-define(SERVER, ?MODULE).
-record(state, {table :: map(), writes = 0 :: non_neg_integer()}).

%% API
start_link() -> gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).
put(Key, Value) -> gen_server:cast(?SERVER, {put, Key, Value}).
get(Key) -> gen_server:call(?SERVER, {get, Key}).

%% Callbacks
init([]) -> {ok, #state{table = #{}}}.

handle_call({get, Key}, _From, State = #state{table = T}) ->
    {reply, maps:find(Key, T), State};
handle_call(_, _From, State) ->
    {reply, {error, unknown}, State}.

handle_cast({put, Key, Value}, State = #state{table = T, writes = W}) ->
    io:format("put ~p (~B writes)~n", [Key, W + 1]),
    {noreply, State#state{table = T#{Key => Value}, writes = W + 1}};
handle_cast(_, State) ->
    {noreply, State}.
