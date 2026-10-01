/* ── Comments ── */
/* Reason showcase: warehouse inventory — OCaml with a JS-flavoured syntax.
   /* block comments nest */
   TODO: persist orders. FIXME: partial match in `parse`. */
// Line comments are supported too.

/** Doc comment attached to the next item. */

/* ── Opens and modules ── */
open Belt;
open! Js.Array2;
module List = Belt.List;
include Printf;

module Money = {
  type t = float;
  let zero: t = 0.;
  let add = (a: t, b: t): t => a +. b;
  let toString = (m: t): string => Printf.sprintf("$%.2f", m);
};

module type Priced = {
  type t;
  let price: t => float;
};

module Product: Priced with type t = (string, float) = {
  type t = (string, float);
  let price = ((_, p)) => p;
};

module MakeCounter = (Start: {let initial: int;}) => {
  let count = ref(Start.initial);
  let incr = () => count := count^ + 1;
};

module Counter = MakeCounter({
  let initial = 10;
});

/* ── Literals ── */
let anInt = 42;
let negative = (-7);
let anIntBig = 1_000_000;
let hex = 0xFF;
let octal = 0o755;
let binary = 0b1010;
let int32 = 42l;
let int64 = 42L;
let nativeInt = 42n;
let aFloat = 3.14;
let floatNoFrac = 3.;
let exponent = 1.5e-3;
let exponent2 = 6.022E23;
let floatUnderscore = 1_000.5;
let aChar = 'x';
let escapedChar = '\n';
let hexChar = '\x41';
let decimalChar = '\065';
let quoteChar = '\'';
let aString = "A string with \"quotes\", a \\ backslash, \t tab, \n newline, \x41 hex, \u{1F4E6} unicode, \065 decimal.";
let multiLine = "line one
line two";
let continuation = "continued \
                    on the next line";
let quoted = {|quoted string with "quotes" and \n unescaped|};
let quotedId = {js|quoted with identifier — 📦|js};
let unit = ();
let bool1 = true;
let bool2 = false;
let aTuple = (1, "two", 3.0);
let aList = [1, 2, 3];
let consed = [0, ...aList];
let emptyList = [];
let anArray = [|1, 2, 3|];
let emptyArray = [||];
let aRef = ref(0);

/* ── Types ── */
type status =
  | Pending
  | Paid(float)
  | Cancelled(string)
  | Shipped({carrier: string, tracking: string});

type order = {
  number: int,
  total: float,
  status,
  tags: list(string),
  mutable note: option(string),
};

type point3d = {
  x: float,
  y: float,
  z: float,
};

type result('a, 'e) =
  | Ok('a)
  | Error('e);

type tree('a) =
  | Leaf
  | Node(tree('a), 'a, tree('a));

type alias = (int, string);
type fn = (int, int) => int;
type optionalLabel = (~label: string=?, int) => string;
type poly = [ | `Red | `Green | `Rgb(int, int, int)];
type polyOpen = [> `Red | `Blue];
type polyClosed = [< `Red | `Green > `Red];
type abstractType;
type extensible = ..;
type extensible += Custom(string);
type gadt('a) =
  | Int(int): gadt(int)
  | Str(string): gadt(string);

exception OutOfStock(string);
exception Invalid;

/* ── Functions ── */
let add = (a, b) => a + b;
let addTyped = (a: int, b: int): int => a + b;
let curried = a => b => a + b;
let withLabels = (~sku, ~qty=1, ~price: float, ~note=?, ()) =>
  switch (note) {
  | Some(n) => sku ++ ": " ++ n
  | None => sku
  };
let usage = withLabels(~sku="AC-1001", ~price=19.99, ());
let punned = (~sku, ~qty) => sku ++ string_of_int(qty);
let callPunned = {
  let sku = "x";
  let qty = 2;
  punned(~sku, ~qty);
};
let rec factorial = n => n <= 1 ? 1 : n * factorial(n - 1);
let rec isEven = n => n == 0 ? true : isOdd(n - 1)
and isOdd = n => n == 0 ? false : isEven(n - 1);
let anonymous = x => x * 2;
let placeholder = List.map([1, 2, 3], x => x + 1);
let pipe = [1, 2, 3] |> List.map(_, x => x * 2);
let fastPipe = [1, 2, 3]->List.map(x => x * 2)->List.length;
let polymorphic: 'a. 'a => 'a = x => x;
let (<+>) = (a, b) => a + b;
let (|>>) = (x, f) => f(x);
let ops = 1 <+> 2;

/* ── Pattern matching ── */
let describe = ({number, status, _}) =>
  switch (status) {
  | Pending => Printf.sprintf("#%d pending", number)
  | Paid(on) => Printf.sprintf("#%d paid (%.0f)", number, on)
  | Cancelled(reason) when reason != "" => Printf.sprintf("#%d cancelled: %s", number, reason)
  | Cancelled(_) => Printf.sprintf("#%d cancelled", number)
  | Shipped({carrier, tracking}) => carrier ++ ":" ++ tracking
  };

let matchLiterals = x =>
  switch (x) {
  | 0 => "zero"
  | 1 | 2 | 3 => "small"
  | 4..9 => "digit"
  | _ => "big"
  };

let matchStrings = s =>
  switch (s) {
  | "a" => 1
  | "b" => 2
  | _ => 0
  };

let matchChars = c =>
  switch (c) {
  | 'a'..'z' => `lower
  | 'A'..'Z' => `upper
  | _ => `other
  };

let matchList = l =>
  switch (l) {
  | [] => "empty"
  | [x] => "one"
  | [x, y] => "two"
  | [x, ...rest] => "many"
  };

let matchTuple = ((a, b)) =>
  switch (a, b) {
  | (0, _) | (_, 0) => 0
  | (x, y) when x == y => x
  | (x, y) as pair => x + y
  };

let matchPoly = c =>
  switch (c) {
  | `Red => "red"
  | `Rgb(r, g, b) => string_of_int(r + g + b)
  | _ => "other"
  };

let matchException = f =>
  switch (f()) {
  | v => Ok(v)
  | exception Not_found => Error("missing")
  | exception OutOfStock(sku) => Error(sku)
  };

let revenue = orders =>
  List.fold_left(
    (acc, o) =>
      switch (o.status) {
      | Paid(_) => acc +. o.total
      | _ => acc
      },
    0.0,
    orders,
  );

/* ── Control flow ── */
let control = (n) => {
  if (n > 0) {
    print_endline("positive");
  } else if (n < 0) {
    print_endline("negative");
  } else {
    print_endline("zero");
  };
  for (i in 0 to 3) {
    print_int(i);
  };
  for (i in 3 downto 0) {
    print_int(i);
  };
  let counter = ref(0);
  while (counter^ < 3) {
    counter := counter^ + 1;
  };
  try (raise(Invalid)) {
  | Invalid => print_endline("invalid")
  | OutOfStock(sku) => print_endline(sku)
  | _ => ()
  };
  let ternary = n > 0 ? "yes" : "no";
  ignore(ternary);
  assert(n != 99);
  lazy(n + 1) |> Lazy.force;
};

/* ── Operators ── */
let arithmetic = 1 + 2 - 3 * 4 / 5 mod 2;
let floating = 1.0 +. 2.0 -. 3.0 *. 4.0 /. 5.0 ** 2.0;
let comparison = 1 < 2 && 2 > 1 || 1 <= 2 && 2 >= 1;
let equality = 1 == 1 && 1 != 2 && "a" === "a" && "a" !== "b";
let strings = "a" ++ "b";
let bitwise = 5 land 3 lor 1 lxor 2 lsl 1 lsr 1 asr 1;
let not_ = !true;
let deref = aRef^;
let update = aRef := 5;
let neg = -5 + -.2.0 |> int_of_float;
let recordUpdate = o => {...o, total: 0., note: Some("zeroed")};
let fieldAccess = (o: order) => o.number + o.tags->List.length;
let fieldAssign = (o: order) => o.note = Some("x");
let arrayAccess = anArray[0];
let arraySet = anArray[0] = 10;
let stringAccess = aString.[0];

/* ── Attributes, extensions, externals ── */
[@bs.val] external setTimeout: (unit => unit, int) => float = "setTimeout";
[@bs.module "path"] external join: (string, string) => string = "join";
[@bs.send] external log: (Js.t({..}), string) => unit = "log";
[@deriving show] type shown = {name: string};
[@warning "-27"] let unused = (a, b) => a;
[%raw "console.log('raw js')"];
let rawResult = [%raw "1 + 1"];
let debugged = [%debugger];

/* ── Objects and labels ── */
let obj = {"sku": "AC-1001", "qty": 25};
let sku = obj##sku;
let qty = obj##qty;
let jsObj = Js.Dict.empty();

/* ── JSX ── */
module Badge = {
  [@react.component]
  let make = (~status: string, ~children=React.null) =>
    <span className={"badge " ++ status}> {React.string(status)} children </span>;
};

let page = (~orders) =>
  <div className="orders">
    <h1> {React.string("Orders")} </h1>
    <ul>
      {orders
       ->List.map(o => <li key={string_of_int(o.number)}> {React.string(describe(o))} </li>)
       ->Array.of_list
       ->React.array}
    </ul>
    <Badge status="paid"> <b> {React.string("!")} </b> </Badge>
    <>
      <input value="x" disabled=true onChange={_ => ()} />
    </>
  </div>;

/* ── Main ── */
let orders = [
  {number: 1, total: 120.5, status: Paid(20260924.), tags: ["new"], note: None},
  {number: 2, total: 0., status: Cancelled("duplicate"), tags: [], note: None},
  {number: 3, total: 42., status: Pending, tags: [], note: Some("rush")},
];

List.iter(o => print_endline(describe(o)), orders);
Printf.printf("revenue: %.2f\n", revenue(orders));
