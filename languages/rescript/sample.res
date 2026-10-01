// ReScript 12 — syntax showcase
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
open! Js.Array2 // deprecated: prefer the Array module
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
let withPlaceholder = [1, 2, 3]->Array.reduce(0, (a, b) => a + b)
let underscore = Array.map(_, x => x)
let polymorphic: 'a. 'a => 'a = x => x
let fetchOne = async () => 1
let fetchAll = async () => {
  let a = await fetchOne()
  let b = await Promise.resolve(2)
  a + b
}

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
  Console.log("done")
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

// ── Type spreads, tags, and inline records ──
type point3 = {...point, z: float}
type moreStatus =
  | ...status
  | Refunded(float)
@tag("kind")
type shape =
  | @as("circle") Circle({radius: float})
  | @as("rect") Rect({width: float, height: float})
type inlineRec = Move({x: int, y: int}) | Stop
type recursiveVariant = Num(int) | Add(recursiveVariant, recursiveVariant) | Mul(recursiveVariant, recursiveVariant)
type nestedGeneric<'a, 'b> = array<option<result<'a, 'b>>>
type withDefaults = {name: string, age?: int}
type taggedUnion<'a> = | One('a) | Many(array<'a>)
type objectTypeOpen = {..}
type module_ = module(Priced)
type abstractMod
type asyncFn = int => promise<int>

// ── First-class modules and module features ──
module type Shape = {
  type t
  let area: t => float
}
module Circle: Shape with type t = float = {
  type t = float
  let area = r => 3.14 *. r *. r
}
let firstClass = module(Circle: Shape with type t = float)
module Unpacked = unpack(firstClass: Shape with type t = float)
module FunctorApplied = MakeCounter({
  let initial = 0
})
module Aliased = Money
module type OfModule = module type of Money
module Nested = {
  module Inner = {
    let value = 1
  }
  include Inner
  open Belt.Array
}
module Constrained: {
  type t = private int
  let make: int => t
} = {
  type t = int
  let make = x => x
}
module type WithTypeConstraints = Priced with type t := int

// ── Expression forms ──
let blockExpr = {
  let a = 1
  let b = {
    let c = 2
    c * 2
  }
  a + b
}
let tupleDestructure = {
  let (a, b) = (1, 2)
  let {number, total, _} = orders->Array.getUnsafe(0)
  let [first, second] = [1, 2]
  let list{head, ...tail} = list{1, 2, 3}
  (a, b, number, total, first, second, head, tail)
}
let chainedPipes = [1, 2, 3]->Array.map(x => x + 1)->Array.filter(x => x > 2)->Array.length
let pipePlaceholder = [1, 2, 3]->Array.reduce(0, (acc, x) => acc + x)
let labelledPipe = "abc"->String.slice(~start=0, ~end=2)
let partialLabelled = Array.map(_, x => x * 2)
let namedArgsPunned = (~a, ~b) => a + b
let callPunnedArgs = { let a = 1; let b = 2; namedArgsPunned(~a, ~b) }
let optionalArg = (~x=?, ()) => x
let defaultArg = (~x=5, ()) => x
let typedLabelled = (~x: int, ~y: option<int>=?, ()) => x
let aliasLabel = (~value as v, ~other as o: int) => v + o
let unitFn = () => ()
let nestedFn = (a) => (b) => (c) => a + b + c
let recordPun = {let number = 1; let total = 2.0; {number, total}}
let recordSpreadUpdate = (o: order) => {...o, total: 0.0}
let nestedRecord = {"a": {"b": {"c": 1}}}
let nestedAccess = nestedRecord["a"]["b"]["c"]
let indexAssign = (arr: array<int>) => arr[0] = 5
let optionalChaining = (o: option<order>) => o->Option.flatMap(x => x.note)
let polyvarWithPayload = #Rgb(1, 2, 3)
let polyvarString = #"with-dash"
let intLiteralVariants = (0b1010, 0o17, 0xAF, 1_000, 5., 5.0e3)
let charRange = ('a', '\\')
let unicodeEscapes = "\u00e9 \u{1F4E6} \x41 \101 \o101"
let forLoop = for i in 0 to 2 { Console.log(i) }
let whileLoop = { let i = ref(0); while i.contents < 2 { i := i.contents + 1 } }
let switchOnTuple = switch (1, "a") {
| (1, "a") => true
| (_, _) => false
}
let switchWithGuards = x =>
  switch x {
  | n if n < 0 => "neg"
  | 0 => "zero"
  | n if n > 100 => "big"
  | _ => "pos"
  }
let switchOnStringAndPolyvar = switch (#a, "b") {
| (#a | #b, "b" | "c") => 1
| _ => 0
}
let tryWith = try {
  JSON.parseExn("{")
} catch {
| JsExn(e) => JSON.Null
| _ => JSON.Null
}
let catchPromise = async () => {
  try {
    await Promise.reject(Failure("x"))
  } catch {
  | Failure(msg) => msg
  | _ => ""
  }
}
let asyncBlock = async () => {
  let results = await Promise.all([Promise.resolve(1), Promise.resolve(2)])
  results
}
let optionals = (Some(1), None, Some(Some(2)), Ok(1), Error("e"))
let unaryOps = (-1, -1.0, !true, -.1.0)
let compareOps = (1 < 2, 1 > 2, 1 <= 2, 1 >= 2, 1 == 1, 1 != 2, 1 === 1, 1 !== 2)
let stringConcat = "a" ++ "b" ++ "c"
let ternaryNested = true ? (false ? 1 : 2) : 3
let ifExpression = if true { 1 } else if false { 2 } else { 3 }
let ifWithoutElse = if true { Console.log("x") }
let uncurriedCall = add(1, 2)
let arrayOfFns = [x => x + 1, x => x * 2]
let applyAll = arrayOfFns->Array.map(f => f(1))
let spreadInList = list{1, 2, ...list{3, 4}}
let genericFn = (type a, x: a): a => x
let asAlias = switch Some(5) {
| Some(n) as whole => (n, whole)
| None as nothing => (0, nothing)
}
let exceptionInSwitch = switch Array.getUnsafe([1], 0) {
| value => value
| exception Not_found => 0
}

// ── Decorators and directives ──
@@jsxConfig({version: 4, mode: "automatic"})
@@directive("use client")
@@warning("-44")
@live let kept = 1
@dead let removable = 2
@deprecated("use something else") let old = 4
@unboxed type wrapper = Wrapper(string)
@variadic @module("path") external joinAll: array<string> => string = "join"
@return(nullable) @get external maybeLength: array<int> => option<int> = "length"
@set external setLength: (array<int>, int) => unit = "length"
@get_index external getAt: (array<int>, int) => int = ""
@set_index external setAt: (array<int>, int, int) => unit = ""
@module("fs") @val external readFileSync: (string, string) => string = "readFileSync"
@val @scope("window") external alert: string => unit = "alert"
@val @scope(("process", "env")) external env: dict<string> = "env"
@module external lib: {"version": string} = "lib"
@module("react") external useState: (unit => 'a) => ('a, ('a => 'a) => unit) = "useState"
@react.component
let counter = (~initial=0, ~onChange: int => unit=?) => {
  let (count, setCount) = React.useState(() => initial)
  <button onClick={_ => setCount(c => c + 1)}> {React.int(count)} </button>
}
