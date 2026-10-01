#!/usr/bin/env elixir
# Elixir 1.19 — syntax showcase
# ── Comments ──
# Line comment. TODO: persist bins. FIXME: handle negative stock.

# ── Module attributes and docs ──
defmodule Acme.Warehouse do
  @moduledoc """
  Stock levels and reorder suggestions.

  ## Examples

      iex> Acme.Warehouse.clamp(15, 0, 10)
      10
  """

  @moduledoc since: "1.0.0"
  @vsn "1.0.0"
  @reorder_point 25
  @default_bins ~w(north south east)a
  @behaviour Access
  @compile {:inline, clamp: 3}
  @on_load :init
  @external_resource "priv/stock.csv"
  @type sku :: String.t()
  @type quantity :: non_neg_integer()
  @type item :: %{sku: sku(), qty: quantity(), price: float()}
  @type result(t) :: {:ok, t} | {:error, term()}
  @typep internal :: atom() | binary()
  @opaque handle :: reference()
  @callback audit(item()) :: :ok | {:error, String.t()}
  @macrocallback build(Macro.t()) :: Macro.t()
  @optional_callbacks build: 1

  # ── Imports, aliases, requires, uses ──
  alias Acme.Warehouse.{Bin, Item}
  alias Acme.Warehouse.Supplier, as: Sup
  import Enum, only: [map: 2, filter: 2]
  import List, except: [flatten: 1]
  require Logger
  use GenServer

  # ── Structs and exceptions ──
  defstruct sku: nil, qty: 0, price: 0.0, tags: []

  defmodule StockError do
    defexception message: "stock error", sku: nil

    @impl true
    def exception(opts), do: %__MODULE__{sku: opts[:sku]}
  end

  defprotocol Describable do
    @doc "Describes a thing."
    def describe(thing)
  end

  defimpl Describable, for: Acme.Warehouse do
    def describe(%{sku: sku, qty: qty}), do: "#{sku} x#{qty}"
  end

  # ── Literals ──
  def literals do
    integer = 1_000_000
    hex = 0xFF_EC
    octal = 0o755
    binary = 0b1010_1010
    float = 6.02e23
    float2 = 1.5E-10
    float3 = 3.14_159
    char = ?a
    char_escape = ?\n
    char_uni = ?é
    atom = :warehouse
    quoted_atom = :"with space"
    op_atom = :+
    nil_value = nil
    bool = true and not false
    string = "Warehouse \"north\"\t\n é \u{1F4E6} \x41 \e[0m"
    interp = "Total: #{integer} and #{Float.round(float, 2)} and #{"nested #{integer}"}"
    # deprecated: single-quoted charlists, prefer ~c
    charlist = 'charlist #{integer}'
    heredoc = """
    Heredoc with #{integer} interpolation
      indented line
    """
    # deprecated: charlist heredoc, prefer ~c
    raw_heredoc = '''
    Charlist heredoc
    '''
    sigil_s = ~s(string with #{integer} and "quotes")
    sigil_S = ~S(raw string #{not_interpolated} \n)
    sigil_w = ~w(one two three)
    sigil_w_atoms = ~w(one two)a
    sigil_c = ~c(charlist)
    sigil_r = ~r/^A-\d{3,}$/iu
    sigil_r2 = ~r{(?<sku>[A-Z]-\d+)\s+(?<qty>\d+)}
    sigil_d = ~D[2026-03-01]
    sigil_t = ~T[08:30:00]
    sigil_n = ~N[2026-03-01 08:30:00]
    sigil_u = ~U[2026-03-01 08:30:00Z]
    list = [1, 2, 3]
    keyword = [qty: 5, price: 4.5]
    cons = [0 | list]
    tuple = {:ok, 42, "three"}
    map = %{"a" => 1, b: 2}
    struct = %Item{sku: "A-100", qty: 5}
    updated = %{map | b: 3}
    binary_lit = <<1, 2, 3>>
    binary_str = <<"abc", 0, 255>>
    binary_pat = <<head::8, rest::binary>>
    bitstring = <<1::size(3), 0::1>>
    range = 1..10
    stepped = 1..10//2
    capture = &(&1 * 2)
    named_capture = &Enum.map/2
    pin = ^integer
    {integer, hex, octal, binary, float, float2, float3, char, char_escape, char_uni, atom,
     quoted_atom, op_atom, nil_value, bool, string, interp, charlist, heredoc, raw_heredoc,
     sigil_s, sigil_S, sigil_w, sigil_w_atoms, sigil_c, sigil_r, sigil_r2, sigil_d, sigil_t,
     sigil_n, sigil_u, list, keyword, cons, tuple, map, struct, updated, binary_lit,
     binary_str, binary_pat, bitstring, range, stepped, capture, named_capture, pin}
  end

  # ── Functions ──
  @doc "Clamps a value."
  @spec clamp(integer(), integer(), integer()) :: integer()
  def clamp(value, lo \\ 0, hi \\ 100) when is_integer(value) and value >= lo or hi > lo do
    value |> max(lo) |> min(hi)
  end

  defp private_helper(x), do: x
  defmacro debug(expr) do
    quote do
      IO.inspect(unquote(expr), label: unquote(Macro.to_string(expr)))
    end
  end
  defmacrop hidden_macro, do: :ok
  defdelegate fetch(item, key), to: Map
  defguard is_stocked(qty) when is_integer(qty) and qty > 0
  defguardp is_low(qty) when qty < 5
  defoverridable clamp: 3

  def describe(%__MODULE__{sku: sku, qty: 0}), do: "#{sku}: out of stock"
  def describe(%__MODULE__{sku: sku, qty: qty}) when qty < 5, do: "#{sku}: only #{qty} left"
  def describe(%{sku: sku}), do: "#{sku}: fine"

  def total_value(items) do
    Enum.reduce(items, 0.0, fn %{qty: q, price: p}, acc -> acc + q * p end)
  end

  # ── Control flow ──
  def flow(items, mode) do
    if length(items) > 3 do
      :many
    else
      :few
    end

    # unless is deprecated since 1.18, prefer `if not`
    unless Enum.empty?(items), do: :has_items

    case mode do
      :fast -> :quick
      {:slow, n} when n > 3 -> :very_slow
      [head | _tail] -> head
      %{key: value} -> value
      "string" <> rest -> rest
      ^mode -> :same
      _ -> :other
    end

    cond do
      length(items) == 0 -> :empty
      length(items) < 5 -> :small
      true -> :large
    end

    with {:ok, a} <- fetch_one(items),
         {:ok, b} when b > 0 <- fetch_two(a),
         c = a + b do
      {:ok, c}
    else
      {:error, reason} -> {:error, reason}
      _ -> :unknown
    end

    for item <- items, item.qty > 0, into: %{}, do: {item.sku, item.qty}
    for {k, v} <- %{a: 1}, reduce: 0 do acc -> acc + v end
    for <<c <- "abc">>, do: c

    try do
      raise StockError, sku: "A-100"
    rescue
      e in StockError -> Logger.error("bad bin #{e.sku}")
      ArgumentError -> :arg
      e -> reraise e, __STACKTRACE__
    catch
      :throw, value -> value
      :exit, reason -> {:exit, reason}
    else
      result -> result
    after
      Logger.info("cleanup")
    end

    receive do
      {:stock, sku} -> sku
    after
      1_000 -> :timeout
    end

    spawn(fn -> :ok end)
    send(self(), {:stock, "A-100"})
    throw(:stop)
  end

  # ── Operators ──
  def operators(a, b) do
    _ = a + b - a * b / 2
    _ = div(a, b) + rem(a, b)
    _ = a == b or a != b and a === b or a !== b
    _ = a < b || a <= b && a > b || a >= b
    _ = !a && not b
    _ = a in [1, 2, 3] and a not in [4, 5]
    _ = [1] ++ [2] -- [1]
    _ = "a" <> "b"
    _ = a |> to_string() |> String.upcase()
    _ = a && b || nil
    _ = a ||| b &&& a <<< 1 >>> 1
    _ = ~~~a
    _ = a =~ ~r/x/
    _ = if a, do: 1, else: 2
    x = y = 5
    {x, y}
  end

  # ── OTP callbacks ──
  @impl true
  def init(args), do: {:ok, args}

  @impl GenServer
  def handle_call(:total, _from, state), do: {:reply, state, state}

  @impl true
  def handle_cast({:add, qty}, state), do: {:noreply, state + qty}

  @impl true
  def handle_info(msg, state) do
    Logger.debug(inspect(msg))
    {:noreply, state}
  end

  # ── Doctests and tests ──
  if Mix.env() == :test do
    def test_helper, do: :ok
  end

  defp fetch_one(_), do: {:ok, 1}
  defp fetch_two(_), do: {:ok, 2}
end

# ── Script section ──
items = [%Acme.Warehouse{sku: "A-100", qty: 12, price: 4.5}, %Acme.Warehouse{sku: "C-300", qty: 3, price: 99.0}]

case Enum.filter(items, &(&1.qty <= 25)) do
  [] -> IO.puts("nothing to reorder")
  low -> IO.puts("reorder: " <> Enum.map_join(low, ", ", & &1.sku))
end

IO.puts(:io_lib.format("value ~.2f", [Acme.Warehouse.total_value(items)]))
Task.async(fn -> :ok end) |> Task.await()
Application.put_env(:acme, :bins, 3)
__ENV__.file
__MODULE__

# ── Further constructs ──
defmodule Acme.Warehouse.Extras do
  @moduledoc false
  @derive {Inspect, only: [:sku]}
  @derive [Jason.Encoder]
  @enforce_keys [:sku]
  defstruct [:sku, qty: 0]

  @type t :: %__MODULE__{sku: String.t(), qty: non_neg_integer()}
  @type fun_type :: (integer() -> integer()) | (... -> any())
  @type bin_type :: <<_::8, _::_*16>>
  @type literal_types :: :atom | 1 | 1..10 | [] | [integer()] | [{atom(), term()}] | {} | %{} | %{required(atom()) => term()}
  @spec generic(a) :: a when a: var
  @spec multi(integer()) :: :ok | {:error, reason :: term()}
  @spec ensure(keyword()) :: no_return()

  alias __MODULE__.Helper
  alias Acme.{Warehouse, Warehouse.Bin}
  import Bitwise
  import Kernel, except: [send: 2]
  require Integer

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      import unquote(__MODULE__)
      @opts opts
      def helper, do: unquote_splicing([1, 2])
    end
  end

  defmacro ast(expr), do: Macro.escape(expr)

  def unicode do
    {"café 日本語 📦", ?é, ?\s, ?\\, ?é, ?\x41, <<0xE9::utf8>>, "\u{1F4E6}", ~c"ünïcode"}
  end

  def numbers do
    [0, 1_000, 0xDEAD_beef, 0o17, 0b1_0, 1.0e-3, 1.5E+3, 100.0, 0.5, ?a, ?A]
  end

  def operators(a, b) do
    [
      a + b, a - b, a * b, a / b, a ++ b, a -- b, a <> b, a ** b,
      a and b, a or b, not a, a && b, a || b, !a,
      a == b, a != b, a === b, a !== b, a < b, a > b, a <= b, a >= b,
      a |> b, a <~> b, a ~> b, a <~ b, a ~>> b, a <<~ b, a <<< b, a >>> b,
      a &&& b, a ||| b, bxor(a, b), ~~~a, a in b, a not in b, a =~ b,
      a..b, a..b//2, &(&1 + &2), &Kernel.+/2, &{&1, &2}, &[&1], & &1, ^a
    ]
  end

  def multi_clause do
    fun = fn
      0 -> :zero
      n when n > 0 -> :positive
      _ -> :negative
    end
    fun2 = fn x, y -> x + y end
    fun3 = &(&1 * 2)
    fun.(1) |> fun3.() |> then(&fun2.(&1, 1))
  end

  def streams do
    1..100
    |> Stream.map(&(&1 * 2))
    |> Stream.filter(&Integer.is_even/1)
    |> Stream.take_while(&(&1 < 50))
    |> Enum.to_list()
  end

  def queries do
    import Ecto.Query
    from i in "items",
      where: i.qty > ^5 and i.price < 10.0,
      order_by: [desc: i.qty],
      select: %{sku: i.sku, qty: i.qty},
      limit: 10
  end

  def with_else(x) do
    with {:ok, v} <- x,
         true <- v > 0 do
      v
    else
      {:error, _} = err -> err
      false -> :nonpositive
    end
  end

  def guards(x) when is_atom(x) or is_binary(x) or is_integer(x) and x > 0 or is_map_key(%{}, x) or x in [1, 2], do: x
  def default_args(a, b \\ 1, c \\ [])
  def default_args(a, b, c), do: {a, b, c}

  def pattern_match do
    %{a: a, b: %{c: [h | t]}} = %{a: 1, b: %{c: [1, 2, 3]}}
    [first, second | _] = [1, 2, 3]
    {:ok, <<a::size(4), b::binary-size(2), rest::binary>>} = {:ok, <<1, 2, 3>>}
    %Acme.Warehouse.Extras{sku: sku} = %Acme.Warehouse.Extras{sku: "A-1"}
    "prefix" <> rest = "prefix-rest"
    ^first = 1
    {a, h, t, second, b, rest, sku}
  end

  def exceptions do
    try do
      raise ArgumentError, message: "bad"
    rescue
      e in [ArgumentError, RuntimeError] -> {:error, Exception.message(e)}
    catch
      kind, reason -> {kind, reason}
    after
      :ok
    end
  end

  def process_things do
    pid = spawn_link(fn -> receive do :stop -> :ok end end)
    ref = Process.monitor(pid)
    send(pid, :stop)
    receive do
      {:DOWN, ^ref, :process, ^pid, _reason} -> :down
    after 100 -> :timeout
    end
    Task.Supervisor.async_nolink(Acme.TaskSupervisor, fn -> 1 end)
    Agent.start_link(fn -> %{} end, name: __MODULE__)
    GenServer.call(__MODULE__, {:get, :key}, 5_000)
    Registry.lookup(Acme.Registry, :key)
    DynamicSupervisor.start_child(Acme.Sup, {Acme.Worker, arg: 1})
  end

  def dbg_and_inspect(x) do
    dbg(x)
    IO.inspect(x, label: "x", limit: :infinity, pretty: true)
    IO.puts(:stderr, "err")
    Logger.metadata(request_id: "abc")
    require Logger
    Logger.info(fn -> "lazy #{x}" end, sku: "A-1")
  end

  @doc false
  @deprecated "Use new_fn/0"
  def old_fn, do: :old

  @compile :debug_info
  @after_compile __MODULE__
  @before_compile Acme.Hooks
  @dialyzer {:nowarn_function, unsafe: 0}
  @impl true
  def unsafe, do: :ok

  # Stack of module attributes with various values
  @attr_list [1, 2, 3]
  @attr_map %{a: 1}
  @attr_tuple {:a, "b"}
  @attr_string "string"
  @attr_atom :atom
  @attr_regex ~r/regex/
  @attr_fun &Kernel.is_atom/1
end

# Config-style DSL
import Config
config :acme, Acme.Repo,
  url: System.get_env("DATABASE_URL", "ecto://user:example-not-a-real-password@db.example.com/acme"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  ssl: true
config :logger, :console, format: "$time $metadata[$level] $message\n", metadata: [:request_id]
if config_env() == :prod, do: config(:acme, debug: false)

# Mix project
defmodule Acme.MixProject do
  use Mix.Project
  def project, do: [app: :acme, version: "1.0.0", elixir: "~> 1.15", deps: deps()]
  defp deps, do: [{:jason, "~> 1.4"}, {:plug, ">= 1.0.0", only: [:dev, :test], runtime: false}]
end

# Doctests and ExUnit
defmodule Acme.WarehouseTest do
  use ExUnit.Case, async: true
  doctest Acme.Warehouse
  @tag :slow
  @tag timeout: 1_000
  describe "clamp/3" do
    setup do
      {:ok, bin: %Acme.Warehouse.Bin{}}
    end
    test "bounds the value", %{bin: bin} do
      assert Acme.Warehouse.clamp(15, 0, 10) == 10
      refute is_nil(bin)
      assert_raise ArgumentError, fn -> raise ArgumentError end
      assert {:ok, _} = {:ok, 1}
      assert_receive {:msg, _}, 100
    end
    test "pending", do: flunk("not yet")
  end
end

# ── Elixir 1.15–1.19 additions and remaining forms ──
defmodule Acme.Warehouse.Modern do
  @moduledoc false
  require Record
  Record.defrecord(:bin, :bin, code: nil, qty: 0)

  @typedoc "A sized bin."
  @type t :: %__MODULE__{code: String.t()}
  defstruct [:code]

  def sigils do
    x = 1
    {~s"double quoted", ~s'single quoted', ~s|pipes|, ~s[brackets], ~s<angles>, ~s{braces},
     ~S"""
     raw heredoc \n #{not_interpolated}
     """,
     ~s'''
     single-quote heredoc #{1 + 1}
     ''', ~c"charlist #{x}", ~C"raw charlist", ~w[a b]c, ~W(raw words #{x}),
     ~r"regex"imsxfUu, ~R/raw regex #{x}/}
  end

  def nested_access(data) do
    data |> get_in([:a, :b]) |> then(&put_in(data, [:a, :b], &1))
    update_in(data[:a][:b], &(&1 + 1))
    data[:a][:b]
    data.a.b
    pop_in(data[:a])
    tap(data, &IO.inspect/1)
    is_non_struct_map(data)
  end

  def comprehensions do
    for x <- 1..3, y <- 1..3, x < y, uniq: true, do: {x, y}
    for <<a, b <- <<1, 2, 3, 4>>>>, into: [], do: a + b
    for x <- [1, 2], reduce: %{} do
      acc -> Map.put(acc, x, x * 2)
    end
  end

  def macros(opts) do
    quote do
      def unquote(:"dyn_#{opts}")(), do: unquote(opts)
    end
    ast = quote(do: 1 + 2)
    {:+, _meta, [1, 2]} = ast
    Macro.expand(ast, __ENV__)
    caller = __CALLER__
    {__DIR__, __ENV__.line, caller}
  end

  def anonymous do
    f = fn -> :no_args end
    g = fn %{a: a}, b when is_integer(a) -> a + b end
    h = &Acme.Warehouse.clamp/3
    i = & &1
    {f.(), g.(%{a: 1}, 2), h.(1, 2, 3), i.(:x)}
  end

  def one_line_forms(x), do: if(x, do: 1, else: 2)

  def block_forms(x) do
    if x do
      1
    else
      2
    end
  end

  def atoms do
    [:"quoted atom", :"with-dash", Elixir.Enum, :erlang, :+, :<<>>, :{}, :%{}, nil, true, false,
     :ok?, :done!, "é" <> "ü", __MODULE__.Sub, Foo.Bar.Baz]
  end

  def stdlib_newer do
    [1, 2, 3] |> Enum.map(&(&1 * 2)) |> dbg()
    Date.shift(~D[2026-03-01], month: 1)
    Duration.new!(month: 1)
    ~U[2026-03-01 00:00:00Z] |> DateTime.add(1, :hour)
    JSON.encode!(%{a: 1})
    Keyword.validate!([a: 1], [:a, b: 2])
    :erlang.system_time(:millisecond)
  end

  # Set-theoretic types are inferred in 1.18+; `dynamic()` is usable in specs.
  @spec any_value() :: dynamic()
  def any_value, do: 1
end
