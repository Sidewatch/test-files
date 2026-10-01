// Carbon warehouse inventory: classes, generics, interfaces, choice types.
// Line comments use double slashes; there are no block comments.
// TODO: add destructors for owned buffers.

package Warehouse api;

import Core library "io";
import Core library "range";
import Core library "string";

library "stock" api;

// ── Constants and aliases ───────────────────────────────────────────
let MAX_ITEMS: i32 = 1_000;
let RATIO: f64 = 1.5e-3;
let HEX: i64 = 0xFF_FF;
let BIN: u8 = 0b1010_1010;
let GREETING: String = "Hello, warehouse";
let MULTILINE: String = '''
  A block string literal.
  Indentation is stripped.
  ''';
let RAW: String = #"raw \n no escapes"#;
let ESCAPES: String = "tab\t newline\n quote\" backslash\\ hex\x41 unicode\u{E9} nul\0";
let CHAR_LIKE: i32 = 65;

alias Quantity = u64;
alias Sku = String;

// ── Choice types (enums with payloads) ──────────────────────────────
choice Category {
  Tools,
  Parts,
  Fasteners
}

choice Command {
  Restock(sku: String, amount: u64),
  Remove(sku: String),
  Audit
}

// ── Interfaces ──────────────────────────────────────────────────────
interface Summarizable {
  fn Summary[self: Self]() -> String;
}

interface Comparable {
  fn Less[self: Self](other: Self) -> bool;
}

// ── Classes ─────────────────────────────────────────────────────────
class Item {
  var sku: String;
  var qty: u64;
  var price: f64;
  private var category: Category;

  fn Create(sku: String, qty: u64) -> Item {
    return {.sku = sku, .qty = qty, .price = 0.0, .category = Category.Tools};
  }

  fn IsLow[self: Self]() -> bool {
    return self.qty < 25;
  }

  fn Restock[addr self: Self*](amount: u64) {
    self->qty += amount;
  }

  impl as Summarizable {
    fn Summary[self: Self]() -> String {
      return self.sku;
    }
  }

  extend impl as Comparable {
    fn Less[self: Self](other: Self) -> bool {
      return self.qty < other.qty;
    }
  }
}

base class Shape {
  virtual fn Area[self: Self]() -> f64;
  abstract fn Name[self: Self]() -> String;
}

class Circle {
  extend base: Shape;
  var radius: f64;
  impl fn Area[self: Self]() -> f64 { return 3.14159 * self.radius * self.radius; }
}

// ── Generics ────────────────────────────────────────────────────────
class Pair(T:! type) {
  var first: T;
  var second: T;

  fn Make(a: T, b: T) -> Pair(T) {
    return {.first = a, .second = b};
  }

  fn Swapped[self: Self]() -> Pair(T) {
    return {.first = self.second, .second = self.first};
  }
}

fn Largest[T:! Comparable & Copy](a: T, b: T) -> T {
  if (a.Less(b)) {
    return b;
  }
  return a;
}

fn Print[T:! Summarizable](value: T) {
  Core.Print(value.Summary());
}

fn Identity(T:! type, x: T) -> T { return x; }

// ── Functions and operators ─────────────────────────────────────────
fn Sum(n: i32) -> i32 {
  var total: i32 = 0;
  var i: i32 = 1;
  while (i <= n) {
    total += i;
    ++i;
  }
  return total;
}

fn Classify(qty: u64) -> String {
  match (qty) {
    case 0 => { return "empty"; }
    case 1 | 2 => { return "scarce"; }
    case n: u64 if n < 25 => { return "low"; }
    default => { return "ok"; }
  }
}

fn Operators(a: i32, b: i32) -> i32 {
  var c: i32 = a + b - a * b / 2 % 3;
  c += 1; c -= 1; c *= 2; c /= 2; c %= 5;
  c = (a & b) | (a ^ b) | ^a;
  c = a << 1 >> 1;
  var logic: bool = (a < b) and (b <= 10) or not (a == b) and (a != b) and (a >= b);
  var ternary: i32 = if logic then a else b;
  var ptr: i32* = &c;
  *ptr = 7;
  var maybe: Optional(i32) = Optional(i32).None;
  var cast: i64 = c as i64;
  return c;
}

// ── Control flow ────────────────────────────────────────────────────
fn Flow(items: [Item; 3]) -> i32 {
  var count: i32 = 0;
  for (item: Item in items) {
    if (item.IsLow()) {
      count += 1;
      continue;
    } else if (item.qty > 1000) {
      break;
    } else {
      count += 0;
    }
  }
  var tuple: (i32, f64, String) = (1, 2.5, "three");
  var array: [i32; 4] = (1, 2, 3, 4);
  var struct_value: {.x: i32, .y: i32} = {.x = 1, .y = 2};
  returned var result: i32 = 0;
  return var;
}

fn Run() -> i32 {
  let p: Pair(i32) = Pair(i32).Make(3, 4);
  let q: Pair(i32) = p.Swapped();
  var item: Item = Item.Create("A-100", 12);
  item.Restock(5);
  Core.Print(q.first + Sum(10));   // 4 + 55
  Print(item);
  let c: Command = Command.Restock("A-100", 5);
  let t: bool = true;
  let f: bool = false;
  let nothing: () = ();
  return 0;
}

// ── Namespaces and testing hooks ────────────────────────────────────
namespace Internal;
fn Internal.Helper() -> i32 { return 1; }
private fn Hidden() {}
impl i32 as Summarizable {
  fn Summary[self: Self]() -> String { return "int"; }
}
constraint HasLength { fn Length[self: Self]() -> i32; }

// ── Further constructs ──────────────────────────────────────────────
import Core library "prelude/types/int";
import library "other" impl;

// Package-level declarations and visibility
private class InternalHelper {}
protected fn ProtectedFn() {}
private let SECRET: i32 = 1;
private alias HiddenAlias = i32;
export fn Exported() -> i32 { return 1; }

// All numeric and literal types
let i8_: i8 = -128;
let i16_: i16 = 32_767;
let i64_: i64 = 9_223_372_036_854_775_807;
let u8_: u8 = 255;
let u16_: u16 = 0xFFFF;
let u32_: u32 = 0b1111_0000;
let u64_: u64 = 1_000_000;
let iN_: Core.Int(128) = 0;
let uN_: Core.UInt(256) = 0;
let f32_: f32 = 1.5;
let f64_: f64 = 2.5e10;
let f_exp: f64 = 0x1.8p3;
let bool_: bool = true;
let str_: String = "string";
let strref: str = "string";
let unit: () = ();
let never_: Core.Never;
let type_: type = i32;
let tuple_type: (i32, String) = (1, "x");
let struct_type: {.a: i32, .b: String} = {.a = 1, .b = "x"};
let array_type: [i32; 3] = (1, 2, 3);
let ptr_type: i32* = Core.Null;
let opt_ptr: Core.Optional(i32*) = Core.None;
let str_multi: String = '''
    Block string
      with indentation
    ''';
let str_hash: String = #'''
    raw with #{interpolation-like} not parsed
    '''#;
let str_hash2: String = ##"double hash "quoted" \##n"##;
let escapes2: String = "bs\\ sq\' dq\" nl\n cr\r tab\t nul\0 hex\x7F uni\u{1F600}";

// Generics, constraints, and facets
fn Compose[T:! type, U:! type, V:! type](f: T, g: U) -> V;
fn Apply[Ts:! type](x: Ts, f: fn(Ts) -> Ts) -> Ts { return f(x); }
fn WithWhere[T:! Container where .ElementType = i32](c: T) {}
fn WithImpls[T:! type where T is Printable and T is Copy](x: T) {}
fn WithEquals[T:! Equal where .Result == bool](x: T) {}
fn Specialised[template T:! type](x: T);
fn Deduced[T: type](x: T);
fn Symbolic(N:! i32) -> [i32; N];
fn AddrSelf[addr self: Self*]();
fn Forall(forall [T:! type] (x: T));

interface Container {
  let ElementType:! type;
  fn Get[self: Self](index: i32) -> ElementType;
  fn Size[self: Self]() -> i32;
  default fn Describe[self: Self]() -> String { return "container"; }
  final let Capacity:! i32 = 16;
}

interface Printable extends Core.Stringable {
  fn Print[self: Self]();
}

constraint Numeric {
  extend Add;
  extend Mul;
  extend Core.As(i64);
}

named_constraint HasToString {
  fn ToString[self: Self]() -> String;
}

class Box(T:! type) {
  var value: T;
  fn Make(v: T) -> Self { return {.value = v}; }
  fn Get[self: Self]() -> T { return self.value; }
  let Element:! type = T;
  adapt T;
  extend base: Container;
  impl as Core.Destroy {
    fn Op[addr self: Self*]() {}
  }
  impl forall [U:! type] as Core.ImplicitAs(Box(U)) where T is Core.ImplicitAs(U) {
    fn Convert[self: Self]() -> Box(U) { return Box(U).Make(self.value); }
  }
  destructor { }
  class Nested { var inner: i32; }
  alias Alias = T;
  let Pi:! f64 = 3.14159;
}

abstract class AbstractShape {
  abstract fn Area[self: Self]() -> f64;
  virtual fn Name[self: Self]() -> String { return "shape"; }
}

class Rect {
  extend base: AbstractShape;
  impl fn Area[self: Self]() -> f64 { return 1.0; }
  override fn Name[self: Self]() -> String { return "rect"; }
}

choice Option(T:! type) {
  Some(value: T),
  None
}

fn UseChoice(o: Option(i32)) -> i32 {
  match (o) {
    case .Some(v: i32) if v > 0 => { return v; }
    case .Some(_: i32) => { return 0; }
    case .None => { return -1; }
  }
}

fn Patterns() {
  var (a: i32, b: String) = (1, "x");
  var {.x = px: i32, .y = py: i32} = {.x = 1, .y = 2};
  let (first: i32, ...) = (1, 2, 3);
  var [p: i32; 3] = (1, 2, 3);
  match ((1, 2)) {
    case (x: i32, 2) => {}
    case (_: i32, _: i32) => {}
  }
  let t:! type = i32;
  let s: Core.String = "x";
  var s2: String = s;
  returned var r: i32 = 0;
  if (r > 0) { return var; }
  while (true) { break; }
  for (x: i32 in Core.Range(10)) { continue; }
  var p: i32* = &r;
  var q: i32* = Core.Heap.New(5);
  Core.Heap.Delete(q);
  *p = 3;
  var fnptr: fn(i32) -> i32 = Identity;
  var x: i32 = fnptr(3);
  var bits: u32 = 1 << 3 | 2 & 3 ^ 4;
  var logic: bool = (x == 3) and (x != 4) or not (x < 2);
  var arith: i32 = x + 1 - 2 * 3 / 4 % 5;
  var neg: i32 = -x;
  var cmp: bool = x <= 3 and x >= 1 and x < 4 and x > 0;
  var cast: i64 = x as i64;
  var inc: i32 = ++x;
  var dec: i32 = --x;
  x += 1; x -= 1; x *= 2; x /= 2; x %= 3; x &= 1; x |= 2; x ^= 3; x <<= 1; x >>= 1;
  var cond: i32 = if x > 0 then 1 else 2;
  var arr: [i32; 3] = (1, 2, 3);
  var elt: i32 = arr[0];
  var tup: (i32, i32) = (1, 2);
  var tfirst: i32 = tup.0;
  var st: {.a: i32} = {.a = 1};
  var sa: i32 = st.a;
  var fq: i32 = Core.Abs(-1);
  var generic: Box(i32) = Box(i32).Make(1);
  var method: i32 = generic.Get();
  var arrow: i32 = p->x;
  var selfref: Self;
  var as_type: type = i32 as type;
  __builtin_unreachable();
}

// TODO: add interop with C++ via `import Cpp library "..."`.
import Cpp library "<vector>";
fn CppInterop() { Cpp.std.vector(i32).Make(); }
fn Identity(x: i32) -> i32 { return x; }
