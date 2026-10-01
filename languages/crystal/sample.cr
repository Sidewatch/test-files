#!/usr/bin/env crystal
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
  Integer.new("5")
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
  def -@; self; end
  def +@; self; end
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
