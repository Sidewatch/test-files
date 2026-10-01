//// Module documentation: a typed inventory pipeline in Gleam.
//// Covers every syntactic category the language has.

// ── Comments ──
// Regular line comment. TODO: split into modules. FIXME: rounding.
/// Documentation comment for the item below.

// ── Imports ──
import gleam/bit_array
import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order.{type Order, Eq, Gt, Lt}
import gleam/result
import gleam/string
import gleam/string_tree as tree

// ── Constants ──
const max_items = 128
const warehouse_name: String = "Acme Warehouse"
const reorder_points = [10, 25, 50]
const origin = #(0, 0)
const flags = Flags(verbose: True, retries: 3)
const greeting = "Hello, " <> warehouse_name

// ── Type aliases ──
pub type Sku =
  String

pub type Prices =
  Dict(Sku, Int)

// ── Custom types: records, enums, generics, opaque ──
pub type Item {
  Item(sku: Sku, pence: Int, tags: List(String))
}

/// A sum type with payloads of several shapes.
pub type ParseError {
  BadNumber(String)
  Missing
  OutOfRange(value: Int, min: Int, max: Int)
}

pub type Flags {
  Flags(verbose: Bool, retries: Int)
}

pub type Tree(a) {
  Leaf
  Node(left: Tree(a), value: a, right: Tree(a))
}

pub type Pair(a, b) {
  Pair(first: a, second: b)
}

pub opaque type Stock {
  Stock(items: List(Item))
}

@external(erlang, "lists", "reverse")
@external(javascript, "./ffi.mjs", "reverse")
pub fn reverse_native(items: List(a)) -> List(a)

@deprecated("Use total/1 instead")
pub fn old_total(lines: List(String)) -> Int {
  total(lines)
}

@internal
pub fn helper() -> Nil {
  Nil
}

// ── Literals ──
pub fn literals() {
  let integer = 42
  let negative = -17
  let grouped = 1_000_000
  let hex = 0xFF
  let octal = 0o755
  let binary = 0b1010_0101
  let float = 3.14
  let exponent = 6.02e23
  let neg_exponent = 1.5e-3
  let truthy = True
  let falsy = False
  let nothing = Nil
  let text = "A string with \"quotes\", \\ backslash, \n newline, \t tab, \r return, \u{1F600} emoji, \u{e9}"
  let multi = "Strings can
span several lines."
  let tuple = #(1, "two", 3.0)
  let list = [1, 2, 3]
  let prepended = [0, ..list]
  let empty = []
  let bits = <<1, 2, 3>>
  let sized = <<7:size(4), 1:size(4)>>
  let bytes = <<"hello":utf8, 0xFF:int, 3.14:float, 1:big-size(16), 2:little-size(16)>>
  let typed = <<1:int-unsigned-size(8), "x":utf8, rest:bytes>>
  #(integer, negative, grouped, hex, octal, binary, float, exponent, neg_exponent)
  |> io.debug
  #(truthy, falsy, nothing, text, multi, tuple, prepended, empty, bits, sized, bytes, typed)
}

// ── Operators ──
pub fn operators(a: Int, b: Int, x: Float, y: Float) {
  let arith = a + b - a * b / a % b
  let farith = x +. y -. x *. y /. x
  let comparison = a == b || a != b && a < b || a <= b || a > b || a >= b
  let fcomparison = x <. y || x <=. y || x >. y || x >=. y
  let negate = !comparison
  let neg = -a
  let concat = "a" <> "b" <> "c"
  let piped = a |> int.to_string |> string.append("x")
  #(arith, farith, fcomparison, negate, neg, concat, piped)
}

// ── Functions ──
fn private_add(a: Int, b: Int) -> Int {
  a + b
}

pub fn labelled(sku sku: String, with_price price: Int) -> Item {
  Item(sku:, pence: price, tags: [])
}

pub fn generic_first(items: List(a), default: a) -> a {
  case items {
    [first, ..] -> first
    [] -> default
  }
}

pub fn anonymous() {
  let double = fn(x) { x * 2 }
  let typed = fn(x: Int) -> Int { x + 1 }
  let captured = int.add(1, _)
  let curried = list.map([1, 2, 3], double)
  #(double(2), typed(3), captured(4), curried)
}

// ── Pattern matching ──
pub fn parse(line: String) -> Result(Item, ParseError) {
  case string.split(line, ",") {
    [sku, price] ->
      int.parse(price)
      |> result.map_error(fn(_) { BadNumber(price) })
      |> result.map(fn(p) { Item(sku, p, []) })
    _ -> Error(Missing)
  }
}

pub fn classify(n: Int) -> String {
  case n {
    0 -> "zero"
    1 | 2 | 3 -> "small"
    x if x < 0 -> "negative"
    x if x > 100 && x < 1000 -> "large"
    _ -> "other"
  }
}

pub fn deep_patterns(value: Result(Option(#(Int, String)), String)) {
  case value {
    Ok(Some(#(0, _))) -> "zero tuple"
    Ok(Some(#(n, name))) if n > 0 -> name
    Ok(None) -> "none"
    Error("fatal") -> "fatal"
    Error(message) -> message
    Ok(_) -> "other"
  }
}

pub fn string_patterns(s: String) {
  case s {
    "hello" <> rest -> rest
    "" -> "empty"
    _ -> s
  }
}

pub fn list_patterns(items: List(Int)) {
  case items {
    [] -> 0
    [only] -> only
    [a, b] -> a + b
    [first, second, ..rest] -> first + second + list.length(rest)
  }
}

pub fn alias_patterns(item: Item) {
  case item {
    Item(sku: "A-1" as sku, ..) -> sku
    Item(pence: p, ..) as whole if p > 100 -> whole.sku
    Item(..) -> "other"
  }
}

pub fn multi_subject(a: Int, b: Int) {
  case a, b {
    0, 0 -> "both zero"
    x, y if x == y -> "equal"
    _, _ -> "different"
  }
}

pub fn bit_patterns(data: BitArray) {
  case data {
    <<1, rest:bytes>> -> rest
    <<a:size(8), b:size(8)>> -> <<a + b>>
    <<"GIF":utf8, _:bytes>> -> data
    _ -> <<>>
  }
}

// ── Let assert, use, todo, panic ──
pub fn control(input: String) -> Int {
  let assert Ok(number) = int.parse(input)
  let assert [first, ..] = [number]
  let assert Some(x) = Some(first) as "must be present"
  use value <- result.try(Ok(x))
  use <- bool_guard(value > 0)
  value
}

fn bool_guard(condition: Bool, otherwise: fn() -> Int) -> Int {
  case condition {
    True -> otherwise()
    False -> 0
  }
}

pub fn unfinished() {
  todo as "implement the reorder report"
}

pub fn impossible() {
  panic as "unreachable state"
}

pub fn blocks() {
  let result = {
    let a = 1
    let b = 2
    a + b
  }
  let updated = Item(..labelled("Z", 5), pence: 6)
  #(result, updated)
}

// ── Records access, update, tuples access ──
pub fn access(item: Item) {
  let sku = item.sku
  let pair = #(1, 2)
  let first = pair.0
  let second = pair.1
  #(sku, first, second)
}

// ── Recursion and tail calls ──
pub fn total(lines: List(String)) -> Int {
  lines
  |> list.filter_map(parse)
  |> list.map(fn(item) { item.pence })
  |> int.sum
}

pub fn sum_to(n: Int, acc: Int) -> Int {
  case n {
    0 -> acc
    _ -> sum_to(n - 1, acc + n)
  }
}

pub fn compare_items(a: Item, b: Item) -> Order {
  case int.compare(a.pence, b.pence) {
    Lt -> Lt
    Eq -> string.compare(a.sku, b.sku)
    Gt -> Gt
  }
}

// ── Imports with aliases and unqualified items ──
import gleam/list.{map as map_list, filter, type List as GleamList}
import gleam/option as opt
import gleam/result.{try, unwrap}

// ── Target-specific code ──
@target(erlang)
pub fn platform() -> String {
  "erlang"
}

@target(javascript)
pub fn platform() -> String {
  "javascript"
}

// ── Public constants and more literals ──
pub const default_limit = 10
pub const bits_const = <<"GIF89a":utf8, 1:size(16)>>
pub const nested_const = [#(1, "a"), #(2, "b")]
pub const record_const = Item("A-1", 100, [])
pub const string_const = "constant"
pub const negative_const = -5
pub const float_const = 1.0e-3

pub fn more_literals() {
  let a = 1_000
  let b = 0b1111_0000
  let c = 0o17
  let d = 0XFF
  let e = 1.0e3
  let f = 1_000.5
  let g = 5.0e-2
  let h = 0.0
  let i = "emoji \u{1F600} tab\t newline\n cr\r quote\" backslash\\ unicode \u{00e9}"
  let j = <<1:size(1), 0:size(7)>>
  let k = <<255:unsigned, -1:signed, 1:big, 1:little, 1:native, 3:unit(8)-size(2)>>
  let l = <<"abc":utf8, "def":utf16, "ghi":utf32, 128512:utf8_codepoint, 128512:utf16_codepoint, 128512:utf32_codepoint>>
  let m = <<1.5:float, 1.5:float-size(32), 1.5:float-big, 1.5:float-little>>
  let n = <<j:bits, k:bytes, l:bits>>
  #(a, b, c, d, e, f, g, h, i, j, k, l, m, n)
}

// ── echo, assert and panic forms ──
pub fn debugging() {
  echo "debug value"
  echo [1, 2, 3] as "list"
  let value = echo 42
  assert value == 42
  assert value > 0 as "value must be positive"
  value
}

// ── Operators on every numeric type ──
pub fn all_operators(a: Int, b: Int, x: Float, y: Float, p: Bool, q: Bool) {
  #(
    a + b, a - b, a * b, a / b, a % b,
    x +. y, x -. y, x *. y, x /. y,
    a == b, a != b, a < b, a <= b, a > b, a >= b,
    x <. y, x <=. y, x >. y, x >=. y,
    p && q, p || q, !p, -a,
    "a" <> "b",
    [1, ..[2, 3]],
  )
}

// ── Nested use, blocks, and functions returning functions ──
pub fn make_adder(n: Int) -> fn(Int) -> Int {
  fn(x) { x + n }
}

pub fn nested_use() {
  use a <- result.try(Ok(1))
  use b <- result.try(Ok(2))
  use _ <- result.try(Ok(Nil))
  use #(c, d) <- result.try(Ok(#(3, 4)))
  use Item(sku: s, ..) <- result.try(Ok(Item("S", 1, [])))
  Ok(a + b + c + d + string.length(s))
}

pub fn higher_order() {
  let add_one = make_adder(1)
  let pipeline =
    [1, 2, 3]
    |> map_list(add_one)
    |> filter(fn(x) { x > 2 })
    |> list.fold(0, fn(acc, x) { acc + x })
  let with_capture = list.map([1, 2, 3], int.multiply(2, _))
  let wildcard_capture = list.map([1, 2, 3], fn(_) { 0 })
  #(pipeline, with_capture, wildcard_capture)
}

// ── Type with type parameters, recursion and unit variants ──
pub type Option2(a) {
  Some2(a)
  None2
}

pub type Json {
  JNull
  JBool(Bool)
  JInt(Int)
  JString(String)
  JList(List(Json))
  JObject(List(#(String, Json)))
}

pub type Result2(ok, err) =
  Result(ok, err)

pub fn depth(tree: Tree(a)) -> Int {
  case tree {
    Leaf -> 0
    Node(left: l, right: r, ..) -> 1 + int.max(depth(l), depth(r))
  }
}

pub fn pattern_aliases(list: List(Int)) {
  case list {
    [1, ..] as whole -> whole
    [_, _, ..] as other if other != [] -> other
    _ -> []
  }
}

pub fn nested_case(value: Result(Result(Int, String), String)) -> String {
  case value {
    Ok(Ok(n)) if n > 0 -> "positive"
    Ok(Ok(_)) -> "non-positive"
    Ok(Error(e)) | Error(e) -> e
  }
}

// ── Tests and entry point ──
pub fn main() {
  let lines = ["A-100,450", "B-200,oops", "C-300,9900"]
  io.println("total: " <> int.to_string(total(lines)))
  io.println(greeting)
  let _ = tree.from_string("x") |> tree.to_string
  let _ = dict.new() |> dict.insert("k", 1)
  let _ = bit_array.byte_size(<<1, 2>>)
  let _ = float.round(3.6)
}
