#!/usr/bin/env ruby
# Ruby 3.4 — syntax showcase
# frozen_string_literal: true
# encoding: utf-8
# warn_indent: true
# ── Comments ──
# Ruby showcase: a warehouse inventory library.
# TODO: persist the catalog. FIXME: tax rounding.

=begin
A block comment delimited by the begin and end markers.
It may span several lines.
=end

# ── Requires ──
require "json"
require "set"
require "forwardable"
require_relative "support/helpers"
autoload :Report, "report"
load "tasks.rb" if false

# ── Constants, globals, special values ──
MAX_ITEMS = 100
DEFAULT_TAX_RATE = 0.075
SKU_PATTERN = /\A(?<prefix>[A-Z]{2})-(?<number>\d{4})\z/x
$stock_log = []
$stdout.sync = true
VERSION = "1.4.0".freeze
nothing = nil
yes = true
no = false
puts __FILE__, __LINE__, __method__.inspect, __dir__, __ENCODING__
puts $0, $PROGRAM_NAME, $;.inspect, $,.inspect, $/.inspect, $!.inspect, $~.inspect, $1.inspect

# ── Numbers ──
integer = 42
negative = -7
underscored = 1_000_000
hex = 0xFF
octal = 0o755
legacy_octal = 0755
binary = 0b1010_0101
float = 3.14
exponent = 1.5e-3
big_exponent = 6.022E23
rational = 3r
rational_frac = 1/3r
complex = 2i
complex_mix = 1+2i
rational_complex = 3ri
character = ?a
infinity = Float::INFINITY
nan = Float::NAN

# ── Strings ──
single = 'single quoted: no #{interpolation}, \' escaped quote, \\ backslash'
double = "double quoted: \t tab, \n newline, \e escape, é, \u{1F4E6 1F4E7}, \x41, \101, \cA, \M-a, \s, \\ "
interpolated = "#{single.length} chars, #{integer + 1} next, #{"nested #{integer}"}, #@instance_var, #$global, #@@class_var"
percent_q = %q(single quoted (nested parens) #{no})
percent_qq = %Q[double quoted #{integer}]
percent_bare = %{bare percent #{integer}}
percent_lt = %<angle brackets>
percent_pipe = %|pipe delimiters|
word_array = %w[alpha beta gamma]
word_array_interp = %W[alpha #{integer} gamma\n]
symbol_array = %i[a b c]
symbol_array_interp = %I[a#{integer} b]
shell = %x(echo hello)
backtick = `echo world`
heredoc = <<~HEREDOC
  Indented heredoc with #{interpolation}.
    Keeps relative indentation.
HEREDOC
heredoc_raw = <<~'RAW'
  Raw heredoc: no #{interpolation} and \n stays.
RAW
heredoc_dash = <<-DASH
    Dash heredoc keeps all leading space.
    DASH
heredoc_plain = <<PLAIN
Plain heredoc.
PLAIN
heredoc_call = <<~SQL.strip.gsub(/\s+/, " ")
  SELECT sku, quantity
  FROM stock
  WHERE quantity < 10
SQL
two_heredocs = [<<~ONE, <<~TWO]
  first
ONE
  second
TWO
concatenated = "adjacent " "string " 'literals'
multiline = "line one
line two"
continued = "continued \
on the next line"
format_string = format("%-10s|%5.2f|%05d|%x|%e|%+d", "sku", 3.14159, 42, 255, 12345.678, 7)
percent_format = "%s has %d items" % ["widget", 4]
character_ranges = ("a".."e").to_a

# ── Symbols ──
sym = :symbol
sym_quoted = :"symbol with spaces"
sym_interp = :"dyn_#{integer}"
sym_op = %i[+ - * / ** == <=> [] []= ! =~]
sym_method = :empty?
sym_setter = :name=
hash_sym = { sku: "AC-1001", "qty": 25, "weird key" => 1, 3 => :three, nil => nil }
hash_short = { integer:, float: }

# ── Regex ──
regex = /^AC-\d{4}$/i
regex_interp = /#{Regexp.escape("AC")}-(\d+)/o
regex_percent = %r{^/orders/(\d+)/lines$}mx
regex_flags = /a.b/mixounse
if "AC-1001" =~ SKU_PATTERN
  puts $~[:prefix], $1, $2, $`, $', $+
end
"AC-1001".match(SKU_PATTERN) { |m| puts m[:number] }
"hello world".gsub(/o/) { |c| c.upcase }.sub(/(\w+) (\w+)/, '\2 \1')
"x".tr("a-y", "b-z")

# ── Collections and ranges ──
array = [1, 2, 3, *[4, 5], 6]
nested = [[1, 2], [3, 4]]
range_inclusive = (1..10)
range_exclusive = (1...10)
range_endless = (1..)
range_beginless = (..5)
range_step = (1..10).step(2)
array[0]; array[-1]; array[1..2]; array[1, 2]; array[..1]; array.dig(0)
hash = { "a" => 1, b: 2, **{ c: 3 } }
hash[:b]; hash.fetch(:c, 0); hash.dig(:a)
set = Set.new([1, 2, 3])
a, (b, *c), d = 1, [2, 3, 4], 5
first, *rest = array
*init, last = array
x = y = 0
squares = (1..5).map { |n| n**2 }.select(&:even?).reduce(:+)
safe = hash&.fetch(:b, nil)&.to_s

# ── Operators ──
arith = 1 + 2 - 3 * 4 / 5 % 6 ** 2
unary = -integer + +integer + ~integer + !yes
bitwise = (5 & 3) | (5 ^ 3) << 1 >> 1
comparison = 1 < 2 && 2 > 1 || 1 <= 2 and 2 >= 1 or not 1 == 2
spaceship = 1 <=> 2
case_eq = Integer === 3
match_op = "abc" =~ /b/
not_match = "abc" !~ /z/
identity = integer.equal?(integer)
ternary = integer > 3 ? "big" : "small"
nil_coalesce = nothing || "default"
integer += 1; integer -= 1; integer *= 2; integer /= 2; integer **= 2; integer %= 7
integer &= 3; integer |= 4; integer ^= 1; integer <<= 1; integer >>= 1
nothing ||= "assigned"
yes &&= false
defined_check = defined?(integer)
flip = (1..10).select { |i| true if (i == 3)..(i == 5) }
splat = [*1..3, *"a".."c"]
double_splat = { **hash, d: 4 }
safe_nav = nothing&.length
method_ref = 5.method(:+)
composition = method(:puts) >> method(:p)
curry = ->(a, b) { a + b }.curry[1]
pipe_like = 5.then { _1 + 1 }
numbered = [1, 2, 3].map { _1 * 2 }
it_param = [1, 2, 3].map { it * 2 }

# ── Modules and classes ──
module Inventory
  MAX_ITEMS = 100

  module Taxable
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def tax_rate(rate = nil)
        rate ? @tax_rate = rate : @tax_rate
      end
    end

    def total_price(rate = DEFAULT_TAX_RATE)
      subtotal = price
      subtotal + (subtotal * rate)
    end
  end

  # Represents a single product in the catalog.
  class Product
    include Comparable
    include Taxable
    extend Forwardable

    attr_reader :name, :price
    attr_writer :tags
    attr_accessor :quantity
    def_delegators :@tags, :size, :each

    @@count = 0
    @registry = {}

    class << self
      attr_reader :registry

      def create(*args, **opts, &block)
        new(*args, **opts).tap { |p| block&.call(p) }
      end
    end

    # Constructor with positional, optional, keyword and block params.
    def initialize(name, price = 0.0, *tags, quantity: 0, **extra, &callback)
      @name = name
      @price = price
      @tags = tags
      @quantity = quantity
      @extra = extra
      @@count += 1
      callback&.call(self)
    end

    def <=>(other) = price <=> other.price

    def self.count = @@count

    def to_s
      "#{@name}: $#{format('%.2f', price)}"
    end

    def inspect = "#<Product #{@name}>"

    def ==(other)
      other.is_a?(self.class) && name == other.name
    end

    def +(other) = price + other.price
    def -@ = -price
    def [](key) = @extra[key]
    def []=(key, value)
      @extra[key] = value
    end
    def call(*) = to_s
    def each_tag
      return enum_for(__method__) unless block_given?
      @tags.each { |t| yield t }
    end

    def method_missing(name, *args)
      name.to_s.start_with?("tag_") ? @tags.include?(name.to_s.sub("tag_", "")) : super
    end

    def respond_to_missing?(name, include_private = false) = name.to_s.start_with?("tag_") || super

    protected

    def internal_price = @price

    private

    def secret = "hidden"

    public

    def visible = secret

    private_class_method :new if false
    private def inline_private = 1
  end

  class Perishable < Product
    def initialize(name, price, expires:)
      super(name, price)
      @expires = expires
    end

    def to_s = "#{super} (expires #{@expires})"
  end

  Point = Struct.new(:x, :y) do
    def distance = Math.sqrt(x**2 + y**2)
  end

  Coordinates = Data.define(:lat, :lon)

  # Builds a catalog from a list of raw hashes.
  def self.build_catalog(rows)
    products = rows.map do |row|
      Product.new(row[:name], row[:price].to_f)
    end
    products.first(MAX_ITEMS)
  end

  class StockError < StandardError
    def initialize(msg = "stock error")
      super
    end
  end

  class OutOfStock < StockError; end
end

# ── Methods, blocks, procs, lambdas ──
def greet(name = "world", *rest, greeting: "Hello", **opts, &block)
  puts "#{greeting}, #{name}!"
  yield name if block_given?
  block&.call(name)
end

def endless(x) = x * 2
def predicate? = true
def bang! = self
def setter=(value); @value = value; end
def forward(...) = greet(...)
def anonymous_forward(*, **, &) = greet(*, **, &)

add = lambda { |a, b = 2| a + b }
stabby = ->(x) { x * 2 }
stabby_do = -> (x, y) do
  x + y
end
proc_obj = Proc.new { |x| x }
proc_short = proc { |x, (y, z), *rest, k: 1, &b| x }
add.call(1); add.(1); add[1]; stabby.curry
[1, 2, 3].each_with_index { |value, index| puts "#{index}: #{value}" }
[1, 2, 3].each do |value|
  next if value == 2
  break if value > 5
  redo if false
end

# ── Control flow ──
if integer > 10
  puts "big"
elsif integer > 5
  puts "medium"
else
  puts "small"
end

puts "postfix if" if yes
puts "postfix unless" unless no
unless no then puts "unless block" end
result = if yes then 1 else 2 end

case integer
when 0 then puts "zero"
when 1..5, 6 then puts "small"
when Integer, Float then puts "number"
when /regex/ then puts "regex"
when ->(n) { n > 100 } then puts "huge"
else puts "other"
end

case { name: "widget", price: 9.99, tags: %w[a b] }
in { name: String => name, price: Float => price } if price > 5
  puts "#{name} costs #{price}"
in { name: "gadget" | "gizmo", **rest }
  puts rest
in [Integer => first, *rest]
  puts first
in [0, _] | [_, 0]
  puts "has a zero"
in String | Symbol => any
  puts any
in nil
  puts "nil"
in ^integer
  puts "pinned"
in ^(integer + 1)
  puts "pinned expression"
in 1.. | ..-1
  puts "range"
in [*, { name: "needle" } => found, *post]
  puts found, post
in [*pre, 42, *]
  puts pre
in (Integer | Float) => number
  puts number
in { id: Integer => id, **nil }
  puts id
in Point[_, _] | Point(x: 0)
  puts "point"
in [Integer, Integer] unless integer.zero?
  puts "pair"
else
  puts "no match"
end

config = { db: { user: "admin" } }
config => { db: { user: } }
puts(config in { db: { user: String } })

while integer < 5 do integer += 1 end
until integer.zero? do integer -= 1 end
begin
  integer += 1
end while integer < 3
begin
  integer -= 1
end until integer <= 0
for i in 1..3 do puts i end
for a, b in [[1, 2], [3, 4]]; puts a + b; end
loop do
  break
end
1.upto(3) { |n| print n }
3.downto(1) { |n| print n }
1.step(10, 3) { |n| print n }
5.times { print "." }

# ── Exceptions ──
begin
  raise Inventory::OutOfStock, "no stock"
rescue Inventory::OutOfStock, ArgumentError => e
  puts e.message, e.backtrace&.first
  retry if false
rescue => e
  raise
rescue Exception
  raise RuntimeError.new("wrapped"), cause: nil
else
  puts "no error"
ensure
  puts "cleanup"
end

def risky
  yield
rescue ZeroDivisionError => e
  puts e
ensure
  puts "done"
end

value = Integer("42") rescue 0
catch(:done) do
  throw :done, 5
end
raise "plain runtime error" if false
fail "alias for raise" if false
warn "to stderr"
exit 0 if false
at_exit { puts "bye" }
BEGIN { puts "begin block" }
END { puts "end block" }

# ── Metaprogramming ──
class Object
  def try_it(m, *a) = respond_to?(m) ? public_send(m, *a) : nil
end

Inventory::Product.class_eval do
  define_method(:shout) { name.upcase }
  alias_method :to_str, :to_s
  alias label name
end

obj = Object.new
obj.instance_variable_set(:@secret, 42)
obj.define_singleton_method(:hi) { "hi" }
obj.singleton_class.send(:attr_accessor, :flag)
Inventory.const_get(:Product)
Comparable.instance_method(:clamp)
ObjectSpace.each_object(Class).first
binding.local_variable_get(:integer)
eval("1 + 1")
send(:puts, "dynamic")
undef_method :to_s if false
refine String do
  def shout = upcase + "!"
end

module Shouting
  refine String do
    def yell = upcase
  end
end
using Shouting

# ── More operators, undef, empty statements ──
not_equal = 1 != 2
class Vec
  def +@ = self
  def ~@ = self
  def -@ = self
  def ! = false
  def !=(other) = !(self == other)
  def a; end
  def b; end
  undef a, :b
  undef_method :c rescue nil
end
;;
star_nil = ->(**nil) { 1 }
def no_kwargs(a, **nil); end
guard_unless = case 5
               in Integer => n unless n < 0 then n
               end
legacy_unless_case = case 5
                     when 5 then :five
                     end
puts __LINE__, __FILE__, __ENCODING__
alias new_name old_name rescue nil
p(*[1, 2], **{ a: 1 })
p 1 if defined?(yield)
numbered_it = [[1, 2]].map { |(a, b)| a + b }
hash_shorthand_call = greet(name:) rescue nil
rescue_modifier = raise rescue 1
endless_with_args(a) rescue nil
ractor = Ractor.new { 1 } rescue nil
multiple_assign_nested = (a, b), c = [1, 2], 3
op_assign_index = hash[:a] ||= 1
op_assign_attr = widget&.name ||= "x" rescue nil
safe_assign = nothing&.foo = 1
const_path = ::Inventory::Product
const_assign = Inventory::LIMIT = 5
global_special = [$stderr, $stdin, $PROGRAM_NAME, $0, $*, $$, $?, $:, $", $<, $>, $_, $@, $&]
backref_pre = $`
symbol_float = :"1.5"
character_literal_escape = ?\n
unary_minus_literal = -2 ** 2
lambda_literal_args = ->(a, b = 1, *c, d:, e: 2, **f, &g) {}
block_local = [1].each { |x; y| y = x }
string_continuation = "a" \
  "b"
rescue_in_block = [1].map do |x|
  Integer(x)
rescue ArgumentError
  0
else
  1
ensure
  2
end
if (m = /(?<year>\d+)/ =~ "2020")
  puts year rescue nil
end
while (line = gets) do break end
begin; end
BEGIN { }
# ── Fibers, threads, enumerators ──
fiber = Fiber.new do
  Fiber.yield 1
  2
end
thread = Thread.new { Thread.current[:x] = 1 }
thread.join
enum = Enumerator.new do |y|
  y << 1 << 2
  y.yield 3
end
lazy = (1..Float::INFINITY).lazy.map { |n| n * 2 }.first(3)
queue = Queue.new
mutex = Mutex.new
mutex.synchronize { queue << 1 }

# ── Main ──
widget = Inventory::Product.new("Widget", 9.99)
puts widget.total_price
puts widget.to_s
puts "Total: #{widget.total_price.round(2)}"
printf("%-8s %6.2f\n", widget.name, widget.price)
pp widget
p widget
print "done\n"
__END__
Anything after __END__ is data, readable via DATA.read.
sku,quantity
AC-1001,25
