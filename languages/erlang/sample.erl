%%% ── Comments ──
%%% @doc A supervised stock store showing every Erlang syntactic category.
%%% @author Acme Dev <dev@example.com>
%%% @version 1.0.0
%%% @copyright 2026 Acme Inc.
%%% TODO: persist bins. FIXME: handle negative stock.
%% Function-level comment
% Plain comment
-module(sample).
-behaviour(gen_server).
-vsn("1.0.0").
-author("Acme Dev").

%% ── Exports and imports ──
-export([start_link/0, put/2, get/1, total/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export_type([sku/0, item/0]).
-import(lists, [map/2, filter/2, foldl/3]).
-compile([export_all, nowarn_export_all, {inline, [clamp/3]}]).
-on_load(init_nif/0).
-nifs([native_add/2]).
-deprecated([{old_put, 2, "use put/2"}]).
-optional_callbacks([terminate/2]).
-dialyzer({nowarn_function, unsafe/0}).
-feature(maybe_expr, enable).

%% ── Macros and includes ──
-include("warehouse.hrl").
-include_lib("kernel/include/file.hrl").
-define(SERVER, ?MODULE).
-define(MAX_BINS, 64).
-define(SQUARE(X), ((X) * (X))).
-define(LOG(Fmt, Args), io:format("~s:~p " ++ Fmt ++ "~n", [?FILE, ?LINE | Args])).
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-else.
-define(TEST_ONLY, false).
-endif.
-ifndef(DEBUG).
-define(DEBUG, false).
-endif.
-if(?OTP_RELEASE >= 25).
-define(MODERN, true).
-elif(?OTP_RELEASE >= 20).
-define(MODERN, false).
-else.
-define(MODERN, false).
-endif.
-undef(DEBUG).

%% ── Records and types ──
-record(state, {table = #{} :: map(), writes = 0 :: non_neg_integer(), name :: atom() | undefined}).
-record(item, {sku :: sku(), qty = 0 :: non_neg_integer(), price = 0.0 :: float()}).

-type sku() :: binary() | string().
-type quantity() :: 0..1000000.
-type item() :: #item{}.
-type result(T) :: {ok, T} | {error, term()}.
-opaque handle() :: reference().
-type fun_type() :: fun((integer()) -> integer()).
-type bits() :: <<_:8, _:_*16>>.

-spec put(sku(), term()) -> ok.
-spec get(sku()) -> {ok, term()} | error.
-spec clamp(integer(), integer(), integer()) -> integer().
-callback audit(item()) -> ok | {error, string()}.

%% ── API ──
start_link() -> gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).
put(Key, Value) -> gen_server:cast(?SERVER, {put, Key, Value}).
get(Key) -> gen_server:call(?SERVER, {get, Key}).

total(Items) ->
    lists:foldl(fun(#item{qty = Q, price = P}, Acc) -> Acc + Q * P end, 0.0, Items).

clamp(Value, Lo, _Hi) when Value < Lo -> Lo;
clamp(Value, _Lo, Hi) when Value > Hi -> Hi;
clamp(Value, _, _) -> Value.

%% ── Literals ──
literals() ->
    Integer = 1_000_000,
    Hex = 16#FF,
    Binary = 2#1010_1010,
    Base36 = 36#ZZ,
    Float = 6.02e23,
    Float2 = 1.5E-10,
    Char = $a,
    CharEscape = $\n,
    CharHex = $\x41,
    CharUni = $\x{E9},
    CharOct = $\101,
    Atom = warehouse,
    QuotedAtom = 'with space',
    Bool = true andalso not false,
    String = "Warehouse \"north\"\t\n \x41 \x{1F4E6} \101 \e \^A",
    Concat = "abc" "def",
    Bin = <<"binary string">>,
    BinBytes = <<1, 2, 3>>,
    BinSized = <<Hex:8, 5:3, 0:5, Float:64/float, Integer:32/big-unsigned-integer>>,
    BinUtf = <<"café"/utf8>>,
    Sigil = ~"sigil string",
    SigilB = ~b"bytes",
    List = [1, 2, 3 | []],
    Cons = [Hex | List],
    Tuple = {ok, 42, <<"three">>},
    Map = #{"a" => 1, b => 2, 3 => three},
    MapUpdate = Map#{b := 20, c => 30},
    Record = #item{sku = <<"A-100">>, qty = 5},
    RecordUpdate = Record#item{qty = 6},
    RecordField = Record#item.qty,
    RecordIndex = #item.qty,
    Fun = fun lists:reverse/1,
    LocalFun = fun clamp/3,
    Anon = fun(X) when X > 0 -> X; (_) -> 0 end,
    NamedFun = fun Loop(0) -> done; Loop(N) -> Loop(N - 1) end,
    Pid = self(),
    Ref = make_ref(),
    {Integer, Hex, Binary, Base36, Float, Float2, Char, CharEscape, CharHex, CharUni, CharOct,
     Atom, QuotedAtom, Bool, String, Concat, Bin, BinBytes, BinSized, BinUtf, Sigil, SigilB,
     List, Cons, Tuple, Map, MapUpdate, Record, RecordUpdate, RecordField, RecordIndex, Fun,
     LocalFun, Anon, NamedFun, Pid, Ref}.

%% ── gen_server callbacks ──
init([]) -> {ok, #state{table = #{}}}.

handle_call({get, Key}, _From, State = #state{table = T}) ->
    {reply, maps:find(Key, T), State};
handle_call(_, _From, State) ->
    {reply, {error, unknown}, State}.

handle_cast({put, Key, Value}, State = #state{table = T, writes = W}) ->
    io:format("put ~p (~B writes)~n", [Key, W + 1]),
    ?LOG("writes: ~p", [W]),
    {noreply, State#state{table = T#{Key => Value}, writes = W + 1}};
handle_cast(_, State) ->
    {noreply, State}.

handle_info({'EXIT', _Pid, Reason}, State) ->
    {stop, Reason, State};
handle_info(_Info, State) -> {noreply, State}.

terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.

%% ── Control flow ──
flow(Items, Mode) ->
    if
        length(Items) > 3 -> many;
        length(Items) > 0, Mode =:= fast -> few;
        true -> none
    end,
    case Mode of
        fast -> quick;
        {slow, N} when is_integer(N), N > 3 -> very_slow;
        [Head | _Tail] -> Head;
        #{key := Value} -> Value;
        <<"str", Rest/binary>> -> Rest;
        _ -> other
    end,
    Result = try
        risky(Items)
    of
        {ok, V} -> V;
        _ -> undefined
    catch
        error:badarg -> badarg;
        throw:stop -> stopped;
        exit:Reason:Stack -> {exit, Reason, Stack};
        _:_ -> unknown
    after
        io:format("cleanup~n")
    end,
    receive
        {stock, Sku} -> Sku;
        {'$gen_call', From, Msg} -> From ! Msg
    after 1000 ->
        timeout
    end,
    [X * 2 || X <- Items, X > 0],
    [{K, V} || {K, V} <- maps:to_list(#{a => 1}), V > 0],
    << <<(C + 1)>> || <<C>> <= <<"abc">> >>,
    #{K => V * 2 || K := V <- #{a => 1}},
    begin A = 1, B = 2, A + B end,
    maybe
        {ok, X1} ?= {ok, 1},
        {ok, X1}
    else
        _ -> error
    end,
    catch error(boom),
    spawn(fun() -> ok end),
    Result.

risky(Items) when is_list(Items) -> {ok, length(Items)};
risky(_) -> error(badarg).

%% ── Operators ──
operators(A, B) ->
    _ = A + B - A * B / 2,
    _ = A div B + A rem B,
    _ = A == B orelse A /= B andalso A =:= B orelse A =/= B,
    _ = A < B orelse A =< B andalso A > B orelse A >= B,
    _ = not A andalso (A xor B),
    _ = A band B bor A bxor B bsl 1 bsr 1,
    _ = bnot A,
    _ = [1] ++ [2] -- [1],
    _ = A ! B,
    _ = - A + (+ B),
    _ = A =:= B,
    ok.

unsafe() -> ok.
init_nif() -> ok.
native_add(_, _) -> erlang:nif_error(not_loaded).

-ifdef(TEST).
simple_test() -> ?assertEqual(10, clamp(42, 0, 10)).
-endif.

%% ── Further constructs ──
%% @doc EDoc tags: {@link sample:put/2}, {@type sku()}, <code>code</code>.
%% @param Key the key
%% @returns `ok'
%% @throws badarg
%% @spec put(Key, Value) -> ok
%% @since 1.0.0
%% @deprecated use {@link put/2}
%% @see get/1
%% @private
%% @end

-moduledoc """
Triple-quoted module documentation.
""".
-doc "Function documentation attribute.".
-doc #{since => "1.0.0"}.
-doc false.

-compile({parse_transform, lager_transform}).
-compile({no_auto_import, [get/1]}).
-compile(inline_list_funcs).
-ignore_xref([{sample, extra, 0}]).
-record(deep, {a = #{} :: #{atom() => term()}, b = <<>> :: binary(), c :: undefined | {ok, term()}}).
-type nested() :: #{atom() => [{integer(), string()}]}.
-type map_assoc() :: #{required(atom()) => term(), optional(binary()) => integer(), atom() := integer()}.
-type fun_arity() :: fun((...) -> any()) | fun(() -> ok) | fun((integer(), atom()) -> boolean()).
-type bytes() :: <<_:_*8>> | <<_:16, _:_*8>>.
-type ranges() :: 0..255 | -10..10 | $a..$z.
-type recs() :: #deep{} | #deep{a :: map()}.
-type any_things() :: any() | term() | none() | no_return() | atom() | pid() | port() | reference() | node() | nil() | [] | [_] | [term(), ...] | maybe_improper_list() | nonempty_string().
-opaque queue(T) :: {[T], [T]}.
-spec lists_flatten([[T]]) -> [T] when T :: term().
-spec bounded(integer()) -> integer() when integer() :: pos_integer().
-callback init2(Args :: term()) -> {ok, State :: term()} | {stop, Reason :: term()}.
-export_type([nested/0, queue/1]).

extras() ->
    %% Strings and characters of every kind
    S1 = "string with \"escapes\" \\ \n \t \r \b \f \v \e \s \d \' \^A \^z \012 \x41 \x{263A}",
    S2 = ~"sigil binary",
    S3 = ~"""
         Triple-quoted
         string
         """,
    S4 = ~s"sigil with ~p",
    S5 = ~S"raw \n sigil",
    S6 = ~b"bytes",
    S7 = ~B"raw bytes",
    %% Atoms
    A = ['simple', 'Quoted Atom', 'with\'quote', 'ünï', '', '+', 'and', '@node', true, false, undefined, ok, error, 'EXIT'],
    C = [$a, $\n, $\\, $\s, $\x41, $\x{263A}, $é, $\^A, $\101],
    N = [1, -1, 0, 16#DEAD_beef, 2#101, 8#777, 36#zz, 1_000, 1.0, -1.5e-3, 1.0e10, 6.022E23, $a],
    %% Binaries
    B1 = <<>>,
    B2 = <<1, 2:4, 3:8/little-signed-integer-unit:1, 4.5:32/float, "str"/utf8, "str"/utf16-big, 5:3/bits, X:Len/binary>>,
    <<H:8, Rest/binary>> = <<1, 2, 3>>,
    <<A1:4, B3:4>> = <<16#AB>>,
    %% Funs
    F1 = fun erlang:abs/1,
    F2 = fun(X) -> X end,
    F3 = fun Named(0) -> 0; Named(N1) -> N1 + Named(N1 - 1) end,
    F4 = fun ?MODULE:extras/0,
    F5 = fun(_) when true -> ok end,
    %% Lists and maps
    L1 = [1, 2 | [3]],
    L2 = [X * 2 || X <- [1, 2, 3], X > 1, X rem 2 =:= 0],
    L3 = [{K, V} || K := V <- #{a => 1}],
    M1 = #{},
    M2 = #{a => 1, "b" => 2, 3 => three, {t} => tuple, [l] => list},
    M3 = M2#{a := 10, new => 1},
    #{a := Va, "b" := Vb} = M3,
    M4 = maps:from_list([{a, 1}]),
    %% Records
    R1 = #deep{},
    R2 = R1#deep{a = #{x => 1}},
    R3 = R2#deep.b,
    #deep{b = Bv} = R2,
    %% Expressions
    Cat = "abc" ++ "def" -- "d",
    Pid = spawn(fun() -> receive stop -> ok end end),
    Pid ! stop,
    Ref = erlang:make_ref(),
    Self = self(),
    Time = erlang:system_time(millisecond),
    Cmp = (1 =:= 1) and (2 =/= 3) or (4 >= 5) xor (6 =< 7) andalso not false orelse true,
    Num = (1 + 2 * 3 - 4 / 5) div 2 rem 3 bsl 1 bsr 1 band 7 bor 8 bxor 1,
    If = if Num > 0 -> pos; Num < 0 -> neg; true -> zero end,
    Cs = case Num of 0 -> zero; N2 when N2 > 0 -> pos; _ -> neg end,
    Catch = catch throw(oops),
    Try = try throw(oops) catch throw:oops -> caught end,
    Try2 = try 1 + 1 of 2 -> two; _ -> other catch _:_ -> err after ok end,
    Block = begin 1, 2, 3 end,
    Rcv = receive M -> M after 0 -> none end,
    Maybe = maybe {ok, V} ?= {ok, 1}, V else _ -> error end,
    Apply = apply(lists, reverse, [[1, 2, 3]]),
    Mfa = {erlang, abs, 1},
    Sq = ?SQUARE(3), Module = ?MODULE, ModStr = ?MODULE_STRING, Fn = ?FUNCTION_NAME, Ar = ?FUNCTION_ARITY, Line = ?LINE, File = ?FILE, Otp = ?OTP_RELEASE,
    ok.

%% Guards, all of them
guards(X) when is_atom(X); is_binary(X), byte_size(X) > 0; is_integer(X), X > 0, X =< 10; is_list(X), length(X) > 1;
               is_tuple(X), tuple_size(X) =:= 2; is_map(X), map_size(X) > 0; is_function(X, 1); is_record(X, deep);
               is_pid(X); is_float(X), abs(X) < 1.0; is_boolean(X); is_number(X); is_reference(X); is_port(X);
               is_bitstring(X); element(1, X) =:= a; hd(X) =:= 1; tl(X) =:= []; node(X) =:= node(); self() =:= X;
               X =:= {} ->
    ok.

%% Preprocessor in function bodies
-ifdef(DEBUG).
debug(Msg) -> io:format("~p~n", [Msg]).
-else.
debug(_) -> ok.
-endif.
-define(IF(C, T, E), case C of true -> T; false -> E end).
-define(assertEq(A, B), (fun() -> true = (A =:= B) end)()).
-define(MACRO_WITH_UNDERSCORE, _).
-export([extras/0, guards/1, debug/1]).
