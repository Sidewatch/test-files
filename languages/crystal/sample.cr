#!/usr/bin/env crystal
# Crystal 1.18 — syntax showcase
# ── Comments ──
# Line comment. TODO: stream the input. FIXME: handle negative stock.
# :nodoc:
# Doc comment for the module. Supports `code` and *emphasis*.
#
# ```
# Warehouse::Bin.new("A-1")
# ```

# ── Requires and flags ──
require "json"
require "yaml"
require "http/client"
require "./bins"
require "spec"

{% if flag?(:release) %}
  puts "release build"
{% elsif flag?(:debug) %}
  puts "debug build"
{% end %}

# ── Constants and top-level lets ──
MAX_BINS   = 64
VERSION    = "1.0.0"
PI_ISH     = 3.14159
EMPTY_SET  = Set(Int32).new
alias Sku = String
alias Prices = Hash(Sku, Float64)

# ── Literals ──
def literals
  int = 1_000_000
  hex = 0xFF_EC
  oct = 0o755
  bin = 0b1010_1010
  typed = [1_i8, 2_i16, 3_i32, 4_i64, 5_u8, 6_u16, 7_u32, 8_u64, 9_i128]
  float = 6.02e23
  float2 = 1.5E-10_f32
  float3 = 2.5_f64
  char = 'a'
  esc_char = '\n'
  uni_char = 'é'
  big_uni = '\u{1F4E6}'
  oct_char = '\101'
  yes = true
  no = false
  nothing = nil

  plain = "Warehouse \"north\"\t\n"
  uni = "café \u{1F4E6} \x41 \101 \e[0m"
  interp = "Total: #{int} and #{float.round(2)} and #{"nested #{int}"}"
  heredoc = <<-TEXT
    Heredoc with #{int} interpolation
      indented line
    TEXT
  raw_heredoc = <<-'RAW'
    Raw heredoc with #{no} interpolation
    RAW
  percent = %(parens "quotes" #{int})
  percent_b = %[brackets]
  percent_c = %{braces}
  percent_a = %<angles>
  percent_p = %|pipes|
  q_raw = %q(no #{interp} here)
  q_interp = %Q(with #{int})
  symbol = :warehouse
  quoted_sym = :"with space"
  op_sym = :+
  sym_array = %i(a b c)
  str_array = %w(one two three)
  regex = /^A-\d{3,}$/i
  regex_x = /(?<sku>[A-Z]-\d+)\s+(?<qty>\d+)/x
  regex_pct = %r{^/stock/(\d+)}
  range = 1..10
  excl = 1...10
  endless = 1..
  array = [1, 2, 3] of Int32
  empty = [] of String
  hash = {"a" => 1, "b" => 2}
  named = {name: "Ada", qty: 5}
  tuple = {1, "two", 3.0}
  empty_hash = {} of String => Int32
  proc = ->(x : Int32) { x * 2 }
  heredoc
end

# ── Enums ──
enum Category : UInt8
  Tools     = 1
  Fasteners
  Safety
  Bulk      = 10

  def label
    to_s.downcase
  end
end

@[Flags]
enum Access
  Read
  Write
end

# ── Annotations ──
annotation Audited
end

# ── Modules and mixins ──
module Auditable
  macro included
    def audit
      puts "audit #{self.class}"
    end
  end

  abstract def id : String
end

module Comparable2(T)
  def compare(other : T) : Int32
    0
  end
end

# ── Structs and classes ──
struct Point
  getter x : Int32
  getter y : Int32

  def initialize(@x : Int32, @y : Int32)
  end

  def +(other : Point) : Point
    Point.new(@x + other.x, @y + other.y)
  end

  def [](i : Int32) : Int32
    i == 0 ? @x : @y
  end

  def ==(other : Point) : Bool
    @x == other.x && @y == other.y
  end
end

struct Hit
  include JSON::Serializable
  getter path : String
  getter status : Int32
  @[JSON::Field(key: "ms")]
  getter millis : Float64
end

@[Audited]
class Item
  include Auditable
  include Comparable(Item)

  @@created = 0
  @sku : String
  property quantity : Int32 = 0
  getter? available : Bool
  setter note : String?
  class_getter total = 0

  def self.created
    @@created
  end

  def initialize(@sku : String, @quantity = 0, @available = true)
    @@created += 1
  end

  def id : String
    @sku
  end

  def <=>(other : Item)
    @sku <=> other.@sku
  end

  def to_s(io : IO) : Nil
    io << "Item(" << @sku << ", " << @quantity << ')'
  end

  def restock(by delta : Int32 = 1, *rest : Int32, **opts) : Int32
    @quantity += delta
  end

  protected def secret; end
  private def hidden; end

  def finalize
    @@created -= 1
  end
end

class Bin < Item
  def initialize(sku : String)
    super(sku, 0)
  end

  def restock(by delta : Int32 = 1, *rest : Int32, **opts) : Int32
    previous_def
    super
  end
end

abstract class Store(T)
  abstract def find(id : String) : T?
end

class MemoryStore(T) < Store(T)
  def initialize
    @data = {} of String => T
  end

  def find(id : String) : T?
    @data[id]?
  end
end

lib LibC
  fun getpid : Int32
  struct Timespec
    tv_sec : Int64
    tv_nsec : Int64
  end
end

# ── Macros ──
macro define_getter(name, type)
  def {{name.id}} : {{type}}
    @{{name.id}}
  end
end

macro debug(expr)
  {% if flag?(:debug) %}
    puts "#{ {{expr.stringify}} } = #{ {{expr}} }"
  {% end %}
  {% for key, value in {a: 1, b: 2} %}
    {% puts key %}
  {% end %}
end

# ── Methods and control flow ──
def clamp(value : Int32, lo = 0, hi = MAX_BINS) : Int32
  value < lo ? lo : (value > hi ? hi : value)
end

def process(items : Array(Item)) : Nil
  if items.empty?
    puts "none"
  elsif items.size == 1
    puts "one"
  else
    puts "many"
  end

  unless items.empty?
    puts "has items"
  end

  puts "inline" if items.size > 3
  puts "unless inline" unless items.empty?

  case items.size
  when 0       then puts "zero"
  when 1, 2    then puts "few"
  when 3..10   then puts "some"
  else              puts "lots"
  end

  case items.first?
  in Item then puts "item"
  in Nil  then puts "nil"
  end

  x = items.first?
  case x
  when Item
    puts x.id
  when Nil
    puts "nil"
  end

  i = 0
  while i < 3
    i += 1
    next if i == 1
    break if i == 2
  end
  until i == 0
    i -= 1
  end
  loop do
    break
  end
  3.times { |n| puts n }
  items.each_with_index do |item, idx|
    puts "#{idx}: #{item}"
  end
  items.map(&.id).select { |s| s.starts_with?("A") }.each { |s| puts s }

  begin
    raise ArgumentError.new("bad bin")
  rescue ex : ArgumentError
    puts ex.message
  rescue
    raise "unknown"
  else
    puts "fine"
  ensure
    puts "cleanup"
  end
end

# ── Operators ──
a, b = 10, 3
a += 1; a -= 1; a *= 2; a //= 3; a %= 5; a **= 2; a <<= 1; a >>= 1; a &= 7; a |= 1; a ^= 3
c = a ** b + a // b - a % b
d = a & b | a ^ b << 1 >> 1
e = !(a < b) && a >= b || a != b && a == b || a <= b
f = a <=> b
g = nil
g ||= 5
g &&= 6
h = g.try &.+(1)
i = g.not_nil!
j = a.is_a?(Int32)
k = a.as(Int32)
l = a.as?(String)
m = a.responds_to?(:+)
n = typeof(a)
o = sizeof(Int32)
p = pointerof(a)
q = ->process(Array(Item))
r = "str" =~ /s/
s = [1, 2, 3].sum { |v| v * 2 }
t = a.nil? ? "nil" : "value"
u = (a > 3 && b < 5) ? 1 : 0
spawn do
  puts "fiber"
end
ch = Channel(Int32).new
spawn { ch.send(1) }
puts ch.receive
select
when v = ch.receive
  puts v
when timeout(1.second)
  puts "timeout"
end

__DIR__
__FILE__
__LINE__

# ── Entry ──
at_exit { puts "bye" }
exit 0 if ARGV.empty?

# ── Further constructs ──
abstract struct Shape
  abstract def area : Float64
end

struct Circle < Shape
  def initialize(@radius : Float64); end
  def area : Float64
    Math::PI * @radius ** 2
  end
end

union_example = uninitialized Int32
ptr = Pointer(Int32).malloc(4)
ptr[0] = 1
ptr.value = 2
(ptr + 1).value = 3

def yielding
  yield 1, 2
end

def with_block(&block : Int32 -> Int32)
  block.call(1)
end

def forwarding(*args, **kwargs, &)
  yield *args, **kwargs
end

yielding { |a, b| puts a + b }
yielding do |a, _|
  puts a
end
puts with_block { |x| x + 1 }
puts [1, 2, 3].map(&.to_s).join(",")
puts [[1, 2], [3, 4]].map { |(a, b)| a + b }
puts({1 => 2}.map { |k, v| k + v })

x = begin
  "5".to_i
rescue ex : ArgumentError | TypeError
  0
rescue ex
  raise ex
end

i = 0
begin
  i += 1
end while i < 3

private macro hidden_macro
  {{ yield }}
end

{% verbatim do %}
  {{ 1 + 2 }}
{% end %}

{% for name in %w(alpha beta) %}
  def {{ name.id }}_value
    {{ name }}
  end
{% end %}

{% if @type.has_method?(:foo) %}
{% end %}

{% begin %}
  {% name = "dynamic" %}
  puts {{ name }}
{% end %}


@[Link("m")]
lib LibM
  fun cos(x : Float64) : Float64
  fun printf(format : UInt8*, ...) : Int32
  alias Callback = Int32 -> Int32
  type Handle = Void*
  union Number
    i : Int32
    f : Float32
  end
  $errno : Int32
  enum Mode
    Read
    Write
  end
end

enum Level
  Debug
  Info
  Warn
  def severe?
    self >= Warn
  end
end

module Outer::Inner
  CONST = 1
  class Deep; end
end

class Generic(T, U)
  def initialize(@a : T, @b : U); end
  forward_missing_to @a
  delegate :size, to: @a
  def method_missing(name, *args); end
  def_equals_and_hash @a
  def_clone
end

class Foo
  def self.build : self
    new
  end
  def ===(other); true; end
  def =~(other); true; end
  def !; false; end
  def -; self; end
  def +; self; end
  def ~; self; end
  def [](*i); end
  def []=(i, v); end
  def []?(i); end
  def <<(x); self; end
  def call(x); end
  def to_unsafe; Pointer(Void).null; end
end

puts "a" "b"
puts "x: %d %s" % [1, "two"]
puts 'a'.ord, 97.chr, "é".bytes, "日本語".size
puts 1.0.to_s, 1e3, 0.1 + 0.2, 7.fdiv(2), 7 // 2, -7 // 2, 7.divmod(2)
puts 1.step(10, 3).to_a, 10.downto(7).to_a, (1..3).each_cons(2).to_a
puts typeof(1 || "a"), typeof(nil), typeof([1, "a"])
puts STDIN.class, STDOUT.class, ARGV.size, ENV["HOME"]?, PROGRAM_NAME
p! x
pp x
print "no newline"
printf "%s\n", "fmt"
sleep 0.01.seconds

# ══ Latest-version additions ═══════════════════════════════════════════

# ── Literals: every number suffix, char and string form ──
def more_literals
  n1 = 1i8; n2 = 2u16; n3 = 3_i32; n4 = 4_u64; n5 = 5i128; n6 = 6u128
  f1 = 1.5f32; f2 = 2.5_f64; f3 = 1e-3; f4 = 1.0e+3_f32; f5 = 1_000.000_1
  b = 0b1111_0000u8
  o = 0o17
  h = 0xDEAD_BEEF_u32
  nul = '\0'
  bell = '\a'
  quote = '\''
  uni = "\u00e9 \u{1F600 1F4E6}"
  hexes = "\x41\x42"
  noint = "\#{not interpolated}"
  mixed = "a" \
          "b"
  shell = `echo hi`
  shell_pct = %x(echo hi)
  ws = %w[a b c]
  ws_brace = %w{x y}
  syms = %i[a b]
  pct_sym = %s(sym)
  regex_flags = /abc/imx
  regex_interp = /#{n1}-\d+/
  gsub = "a-b".gsub(/(?<first>\w)-(\w)/, "\\2-\\k<first>")
  typed_array = Array(Int32).new(3, 0)
  array_lit = Array{1, 2, 3}
  hash_lit = Hash{"a" => 1}
  set_lit = Set{1, 2}
  deque = Deque{1, 2}
  nt = {"quoted key": 1, plain: 2}
  nt2 = NamedTuple(a: Int32, b: String).new(a: 1, b: "x")
  tup = Tuple(Int32, String).new(1, "x")
  static = StaticArray[1, 2, 3]
  static2 = StaticArray(Int32, 3).new(0)
  beginless = ..5
  beginless_excl = ...5
  both = (1..)
  stepped = (1..10).step(2)
  heredoc_call = <<-A.strip
    first
    A
  two = [<<-ONE, <<-TWO]
    one
    ONE
    two
    TWO
  {n1, n2, n3, n4, n5, n6, f1, f2, f3, f4, f5, b, o, h, nul, bell, quote, uni, hexes, noint, mixed}
end

# ── Pattern matching (case/in) ──
def patterns(value : Int32 | String | Nil | Array(Int32) | Tuple(Int32, String) | NamedTuple(name: String))
  case value
  in Int32 then "int"
  in String then "string"
  in Nil then "nil"
  in [Int32, Int32] then "array"
  in {Int32, String} then "tuple"
  in {name: String} then "named"
  end

  pinned = 5
  case 5
  in ^pinned then "pinned"
  in 0..3 then "range"
  in Int32 | Nil then "union"
  in .even? then "predicate"
  in _ then "any"
  end
end

# ── Case/when forms ──
def when_forms(x : Int32 | String)
  case x
  when Int32, String then "types"
  when .nil? then "implicit receiver"
  when 1..10, 20.. then "ranges"
  when /re/ then "regex"
  when "a", "b" then "strings"
  else "other"
  end

  case
  when x.is_a?(Int32) then 1
  when x.is_a?(String) then 2
  end
end

# ── Method definition forms ──
def named_args(from source : String, to target : String = source, *, flag : Bool = false) : String
  "#{source}->#{target} #{flag}"
end
named_args(from: "a", to: "b", flag: true)
named_args "a", "b", flag: true
named_args(**{from: "a"})
named_args(*{"a", "b"})

def one_line = 42
def endless_with_arg(x : Int32) = x * 2
def default_from_other(x, y = x * 2); x + y; end
def rescued
  raise "x"
rescue ex
  ex.message
else
  "no error"
ensure
  puts "always"
end
def self.class_method; end
def Foo.on_type; end
def generic_method(x : T) : T forall T
  x
end
def union_arg(x : Int32 | String | Nil); end
def nilable(x : Int32?); end
def proc_arg(f : Int32 -> String); end
def proc_arg2(f : Proc(Int32, String)); end
def class_arg(k : Int32.class); end
def self_type : self; self; end
def underscore_type(x : _) : _; x; end
def typeof_arg(x : typeof(1 + 1)); end
def double_splat(**opts : Int32); end
def block_forms(&block : Int32 -> Int32); yield 1; end
def anon_block(&); yield; end
def with_receiver
  with self yield
end
def out_param
  LibC.getpid
end

# ── Operators: every one ──
def operators2(a : Int32, b : Int32, f : Float64)
  a &+ b; a &- b; a &* b; a &** b
  a ** b; a // b; a % b; a / b
  a..b; a...b
  a ^ b; a & b; a | b; ~a
  a << b; a >> b
  a <=> b; a === b; a =~ /x/
  a == b; a != b; a < b; a <= b; a > b; a >= b
  !a; -a; +a
  a && b; a || b
  a ||= 1; a &&= 2; a &+= 1; a &-= 1; a &*= 2; a ^= 1
  f.try(&.floor)
  a.try &.succ
  a.nil? ? 1 : 2
  a ? b : f
end

# ── Control flow extras ──
def control_extras(items : Array(Int32))
  x = if items.empty? then 0 else 1 end
  y = unless items.empty? then 1 else 0 end
  z = while true; break 5; end
  items.each do |i|
    next if i < 0
    break if i > 100
    redo_ok = i
  end
  begin
    puts "do-while"
  end while false
  begin
    puts "do-until"
  end until true
  until false; break; end
  for_each = items.each_with_object([] of Int32) { |i, memo| memo << i }
  idx = items.index { |v| v == 2 }
  if (found = items.find(&.even?))
    puts found
  end
  if items.first? && (v = items[0]?)
    puts v
  end
  res = items.sum do |i|
    i * 2
  end
  puts res if res
  puts "ok" unless items.empty?
  return x, y, z
end

# ── Types: unions, generics, aliases, structs ──
alias Json = Nil | Bool | Int64 | Float64 | String | Array(Json) | Hash(String, Json)
alias Handler = Proc(Int32, Nil)
record Coord, x : Int32, y : Int32
record Named, name : String, value : Int32 = 0 do
  def shout; name.upcase; end
end
struct Wrapper(T)
  def initialize(@value : T); end
  def map(&block : T -> U) : Wrapper(U) forall U
    Wrapper.new(yield @value)
  end
end
class Registry(K, V)
  getter! current : V
  property? enabled = true
  class_property count = 0
  class_getter! default : String
  class_setter hook
  @items = {} of K => V
  def self.build(*args, **opts) : self; new; end
  def [](key : K) : V; @items[key]; end
  def []=(key : K, value : V); @items[key] = value; end
  def each(&block : {K, V} ->); @items.each { |k, v| yield({k, v}) }; end
end
class Child < Registry(String, Int32)
  def initialize
    super
    @count = 0
  end
end
module Outer2
  module Inner2
    VALUE = 1
    class Klass; end
    struct Rec; end
    enum E; A; B; end
  end
end
include Outer2
extend Outer2::Inner2
puts ::Outer2::Inner2::VALUE
puts Outer2::Inner2::Klass.name

# ── Annotations (built-in and custom) ──
annotation Route
end
@[Route(path: "/stock", method: "GET")]
@[AlwaysInline]
def annotated_route; end
@[NoInline, Raises]
def raises_a_lot; raise "x"; end
@[Extern]
struct ExternStruct
  x : Int32
end
@[Packed]
struct PackedStruct
  a : UInt8
  b : UInt32
end

# ── Macros: every statement form ──
macro make_getters(*names)
  {% for name, index in names %}
    def {{ name.id }}_{{ index }} : Int32
      {{ index }}
    end
  {% end %}
end
macro conditional(x)
  {%- if x.is_a?(NumberLiteral) -%}
    puts "number"
  {%- elsif x.is_a?(StringLiteral) -%}
    puts "string"
  {%- else -%}
    puts "other"
  {%- end -%}
end
macro with_vars
  {% a = 1 %}
  {% b = [1, 2, 3] %}
  {% c = {x: 1} %}
  {% d = b.map { |v| v * 2 } %}
  {% e = b.select { |v| v > 1 } %}
  {% if a == 1 && !b.empty? || c[:x] %}
    {{ d }}
  {% end %}
  {% for k, v in c %}
    {{ k }} {{ v }}
  {% end %}
  {% for x in b %}
    {% next if x == 2 %}
    {% break if x == 3 %}
  {% end %}
  {% unless a == 2 %}{% end %}
  {% skip_file if false %}
  {% raise "fail" if false %}
  {% debug if false %}
  {% pp a %}
  {% puts a %}
  {{ a }}{{ b }}
  {{ @type }}
  {{ @def }}
  {{ yield }}
  {{ run("./x") if false }}
  {{ system("echo") if false }}
  {{ env("HOME") }}
  {{ read_file("x") if false }}
  {{ flag?(:linux) }}
  {{ compare_versions("1.0", "2.0") }}
end
macro inherited
  puts {{ @type.name.stringify }}
end
macro method_added(method)
  {% puts method.name %}
end
macro finished
  puts "finished"
end
macro splat_macro(*args, **opts, &block)
  {{ args.splat }} {{ opts.double_splat }} {{ block.body }}
end
macro class_def(name)
  class {{ name.id }}; end
end
{% if compare_versions(Crystal::VERSION, "1.0.0") >= 0 %}
  puts "modern"
{% end %}
{% if Crystal::VERSION.starts_with?("1.") %}{% end %}
{{ "literal".id }}

# ── C bindings, unsafe ──
@[Link(ldflags: "-lm")]
lib LibMath
  fun sqrt(x : Float64) : Float64
  fun get_time(t : Int64*) : Int32
  fun callback(f : Int32 -> Int32) : Void
  fun pointer_arg(p : Int32*, pp : Int32**) : Void
  fun c_name = real_c_name(x : Int32) : Int32
  struct Pt
    x, y : Int32
  end
  @[Raises]
  fun risky : Int32
end
fun crystal_exported(x : Int32) : Int32
  x + 1
end
def unsafe_ops
  x = 1
  ptr = pointerof(x)
  puts sizeof(Int32), instance_sizeof(String), alignof(Int32), offsetof(Coord, @y)
  LibMath.get_time(out t)
  buf = uninitialized UInt8[16]
  slice = Slice(UInt8).new(ptr.as(UInt8*), 4)
  casted = ptr.as(UInt8*)
  asm("nop" ::: "volatile")
  {t, buf, slice, casted}
end

# ── Concurrency and misc statements ──
def concurrency
  ch = Channel(Int32).new(2)
  done = Channel(Nil).new
  spawn(name: "worker") { ch.send(1); done.send(nil) }
  select
  when v = ch.receive then puts v
  when done.receive then puts "done"
  when ch.send(2) then puts "sent"
  else puts "none"
  end
  mutex = Mutex.new
  mutex.synchronize { puts "locked" }
  Fiber.yield
end
require "./*"
require "../x/*"
private alias Hidden = Int32
private struct HiddenStruct; end
private class HiddenClass; end
private enum HiddenEnum; A; end
private module HiddenModule; end
private CONST_HIDDEN = 1
x_ok = 1 if false
puts $~, $1?, $?
puts __DIR__, __FILE__, __LINE__, __END_LINE__
puts typeof(x_ok), x_ok.class, x_ok.is_a?(Int32), x_ok.as?(Int32), x_ok.try(&.succ)
puts [1, 2, 3].each_slice(2).to_a, "a,b".split(','), [3, 1, 2].sort_by { |v| -v }
puts "%05.1f|%-5s|%+d" % [1.5, "ab", 3]
puts "tab\there", 'c', :sym, :"quoted sym", :a?, :b!, :c=, :[], :[]?, :<=>, :==, :!
puts 1.0 / 3, 10.0.to_i, "12".to_i?, "x".to_i?, Int32::MAX, Float64::INFINITY, Float64::NAN
STDERR.puts "error"
abort "fatal" if false
raise ArgumentError, "bad" if false
exit(1) if false
