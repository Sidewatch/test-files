// ── Comments ──
// ReScript showcase: warehouse inventory compiled to JS.
// TODO: persist orders. FIXME: partial match in `parse`.

/* A block comment
   /* with a nested block comment */
   spanning lines. */

/** Doc comment attached to the next item. */

/*** Module-level doc comment. */

// ── Opens, modules ──
open Belt
open! Js.Array2
module L = Belt.List
include Belt.Result

module Money = {
  type t = float
  let zero: t = 0.0
  let add = (a: t, b: t): t => a +. b
  let toString = (m: t): string => "$" ++ Float.toFixed(m, ~digits=2)
}

module type Priced = {
  type t
  let price: t => float
}

module Product: Priced with type t = (string, float) = {
  type t = (string, float)
  let price = ((_, p)) => p
}

module MakeCounter = (Start: {let initial: int}) => {
  let count = ref(Start.initial)
  let incr = () => count := count.contents + 1
}

module Counter = MakeCounter({
  let initial = 10
})

@@warning("-27")

// ── Literals ──
let anInt = 42
let negative = -7
let big = 1_000_000
let hex = 0xFF
let octal = 0o755
let binary = 0b1010
let int64 = 42L
let aFloat = 3.14
let noFrac = 3.
let exponent = 1.5e-3
let exp2 = 6.022E23
let aChar = 'x'
let escapedChar = '\n'
let hexChar = '\x41'
let unicodeChar = '\u{1F4E6}'
let aString = "A string with \"quotes\", a \\ backslash, \t tab, \n newline, \x41 hex, é unicode, \u{1F4E6} braces."
let multiLine = "line one
line two"
let template = `Template ${anInt} with ${Int.toString(anInt + 1)} and a "quote" and a \` backtick`
let templateMulti = `Order:
  number: ${Int.toString(1)}
  total: ${Float.toString(1.5)}`
let tagged = String.raw`raw \n ${anInt}`
let unit = ()
let yes = true
let no = false
let aTuple = (1, "two", 3.0)
let aList = list{1, 2, 3}
let consed = list{0, ...aList}
let anArray = [1, 2, 3]
let emptyArray: array<int> = []
let aRef = ref(0)
let dict = dict{"a": 1, "b": 2}
let aBigint = 123n
let anOption = Some(5)
let noOption: option<int> = None

// ── Types ──
type status =
  | Pending
  | Paid(float)
  | Cancelled(string)
  | Shipped({carrier: string, tracking: string})

type order = {
  number: int,
  total: float,
  status: status,
  tags: array<string>,
  mutable note: option<string>,
  @as("order_date") date: string,
  optional?: int,
}

type point = {x: float, y: float}
type rec tree<'a> = Leaf | Node(tree<'a>, 'a, tree<'a>)
type result<'a, 'e> = Ok('a) | Error('e)
type alias = (int, string)
type fn = (int, int) => int
type labelled = (~label: string, ~count: int=?, int) => string
type poly = [#Red | #Green | #Rgb(int, int, int)]
type polyOpen = [> #Red | #Blue]
type polyClosed = [< #Red | #Green > #Red]
type abstractType
type extensible = ..
type extensible += Custom(string)
type gadt<_> =
  | Int(int): gadt<int>
  | Str(string): gadt<string>
type variantWithAs = | @as("pending") Pend | @as(2) Two | @as(true) Yes
type jsObject = {"sku": string, "qty": int}
type withConstraint<'a> = array<'a> constraint 'a = int
type opaque = private string
type promiseOfInt = promise<int>
type uncurried = (. int) => int

exception OutOfStock(string)
exception Invalid

// ── Functions ──
let add = (a, b) => a + b
let addTyped = (a: int, b: int): int => a + b
let curried = a => b => a + b
let withLabels = (~sku, ~qty=1, ~price: float, ~note=?, ()) =>
  switch note {
  | Some(n) => sku ++ ": " ++ n
  | None => sku ++ Int.toString(qty) ++ Float.toString(price)
  }
let usage = withLabels(~sku="AC-1001", ~price=19.99, ())
let punned = (~sku, ~qty) => sku ++ Int.toString(qty)
let callPunned = {
  let sku = "x"
  let qty = 2
  punned(~sku, ~qty)
}
let rec factorial = n => n <= 1 ? 1 : n * factorial(n - 1)
and isEven = n => n == 0 ? true : isOdd(n - 1)
and isOdd = n => n == 0 ? false : isEven(n - 1)
let placeholder = Array.map([1, 2, 3], x => x + 1)
let pipeFirst = [1, 2, 3]->Array.map(x => x * 2)->Array.length
let pipeLast = [1, 2, 3] |> Array.length
let withPlaceholder = [1, 2, 3]->Array.reduce(0, (a, b) => a + b)
let underscore = Array.map(_, x => x)
let polymorphic: 'a. 'a => 'a = x => x
let async fetchAll = async () => {
  let a = await fetchOne()
  let b = await Promise.resolve(2)
  a + b
}
and fetchOne = async () => 1

// ── Pattern matching ──
let describe = order =>
  switch order.status {
  | Pending => `#${order.number->Int.toString} pending`
  | Paid(on) => `#${order.number->Int.toString} paid (${on->Float.toString})`
  | Cancelled(reason) if reason != "" => `#${order.number->Int.toString} cancelled: ${reason}`
  | Cancelled(_) => `#${order.number->Int.toString} cancelled`
  | Shipped({carrier, tracking}) => carrier ++ ":" ++ tracking
  }

let matchLiterals = x =>
  switch x {
  | 0 => "zero"
  | 1 | 2 | 3 => "small"
  | 4..9 => "digit"
  | _ => "big"
  }

let matchStrings = s =>
  switch s {
  | "a" => 1
  | "b" => 2
  | _ => 0
  }

let matchChars = c =>
  switch c {
  | 'a'..'z' => #lower
  | 'A'..'Z' => #upper
  | _ => #other
  }

let matchList = l =>
  switch l {
  | list{} => "empty"
  | list{_} => "one"
  | list{_, _} => "two"
  | list{_, ...rest} => "many"
  }

let matchArray = a =>
  switch a {
  | [] => 0
  | [x] => x
  | [x, y] => x + y
  | _ => -1
  }

let matchTuple = ((a, b)) =>
  switch (a, b) {
  | (0, _) | (_, 0) => 0
  | (x, y) if x == y => x
  | (x, y) as pair => x + y
  }

let matchPoly = c =>
  switch c {
  | #Red => "red"
  | #Rgb(r, g, b) => Int.toString(r + g + b)
  | _ => "other"
  }

let matchException = f =>
  switch f() {
  | v => Ok(v)
  | exception Not_found => Error("missing")
  | exception OutOfStock(sku) => Error(sku)
  }

let matchRecord = ({number, total, _}) => number + Float.toInt(total)
let matchOption = o =>
  switch o {
  | Some(x) if x > 0 => x
  | Some(_) => 0
  | None => -1
  }
let ifLet = switch Some(5) {
| Some(n) => n
| None => 0
}

let revenue = orders =>
  orders
  ->Array.filter(o =>
    switch o.status {
    | Paid(_) => true
    | _ => false
    }
  )
  ->Array.reduce(0.0, (acc, o) => acc +. o.total)

// ── Control flow ──
let control = n => {
  if n > 0 {
    Console.log("positive")
  } else if n < 0 {
    Console.log("negative")
  } else {
    Console.log("zero")
  }
  for i in 0 to 3 {
    Console.log(i)
  }
  for i in 3 downto 0 {
    Console.log(i)
  }
  let counter = ref(0)
  while counter.contents < 3 {
    counter := counter.contents + 1
  }
  try {
    raise(Invalid)
  } catch {
  | Invalid => Console.log("invalid")
  | OutOfStock(sku) => Console.log(sku)
  | _ => ()
  }
  let ternary = n > 0 ? "yes" : "no"
  ignore(ternary)
  assert(n != 99)
  let lazyValue = lazy (n + 1)
  Lazy.force(lazyValue)
}

// ── Operators ──
let arithmetic = 1 + 2 - 3 * 4 / 5 mod 2
let floating = 1.0 +. 2.0 -. 3.0 *. 4.0 /. 5.0 ** 2.0
let comparison = 1 < 2 && 2 > 1 || 1 <= 2 && 2 >= 1
let equality = 1 == 1 && 1 != 2 && "a" === "a" && "a" !== "b"
let strings = "a" ++ "b"
let bitwise = 5->land(3)->lor(1)->lxor(2)->lsl(1)->lsr(1)->asr(1)
let notOp = !true
let deref = aRef.contents
let update = aRef := 5
let negFloat = -.2.0
let spread = {...{x: 1.0, y: 2.0}, x: 3.0}
let fieldAccess = (o: order) => o.number + o.tags->Array.length
let fieldAssign = (o: order) => o.note = Some("x")
let arrayAccess = anArray[0]
let arraySet = anArray[0] = 10
let optionalChain = (o: option<order>) => o->Option.map(x => x.number)
let nullable = Nullable.make(5)
let coalesce = Option.getOr(None, 5)

// ── Decorators, externals, raw ──
@val external setTimeout: (unit => unit, int) => float = "setTimeout"
@module("path") external join: (string, string) => string = "join"
@send external log: (Dict.t<string>, string) => unit = "log"
@scope("Math") @val external floor: float => float = "floor"
@new external makeDate: unit => Date.t = "Date"
@get external length: array<'a> => int = "length"
@module("./styles.module.css") external styles: {"container": string} = "default"
@deriving(accessors) type shown = {name: string}
@unboxed type any = Any('a)
@genType let exported = 5
@inline let inlined = 1
@warning("-27") let unused = (a, b) => a
%%raw("console.log('top-level raw js')")
let rawResult = %raw("1 + 1")
let rawFn: int => int = %raw("function (x) { return x * 2 }")
let debugged = %debugger
let regex = %re("/^AC-\d{4}$/i")
let externalExt = %external(window)

// ── Objects and JSON ──
let obj = {"sku": "AC-1001", "qty": 25}
let sku = obj["sku"]
let json = JSON.parseExn(`{"a": [1, 2, 3]}`)

// ── JSX ──
module Badge = {
  @react.component
  let make = (~status: string, ~children=React.null) =>
    <span className={"badge " ++ status}> {React.string(status)} children </span>
}

@react.component
let make = (~orders: array<order>) =>
  <div className="orders">
    <h1> {React.string("Orders")} </h1>
    <ul>
      {orders
      ->Array.map(o => <li key={Int.toString(o.number)}> {React.string(describe(o))} </li>)
      ->React.array}
    </ul>
    <Badge status="paid"> <b> {React.string("!")} </b> </Badge>
    <>
      <input value="x" disabled=true onChange={_ => ()} />
      <Foo.Bar {...props} baz />
    </>
  </div>

// ── Main ──
let orders = [
  {number: 1, total: 120.5, status: Paid(20260924.0), tags: ["new"], note: None, date: "2026-09-24", optional: ?None},
  {number: 2, total: 0.0, status: Cancelled("duplicate"), tags: [], note: None, date: "2026-09-25", optional: ?Some(1)},
]

orders->Array.forEach(o => Console.log(describe(o)))
Console.log(`revenue: ${revenue(orders)->Float.toString}`)
