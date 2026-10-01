#!/usr/bin/env nim r
## Nim 2.2 — syntax showcase: a typed inventory with procs, iterators, templates and macros.
##
## This is a module-level doc comment. It supports *emphasis*, ``code`` and
## `links <https://example.com>`_ in reStructuredText.

# A line comment
#[ A block comment
   #[ with a nested one ]#
   still inside ]#
#[[ Another block form ]]#
# TODO: stream the report instead of building a seq
# FIXME: sorting is not stable

{.push raises: [].}
{.experimental: "codeReordering".}

import std/[asyncdispatch, strformat, sequtils, algorithm, tables, sets, options, strutils, math, os, times]
import std/json as js
from std/sugar import `=>`, `->`, collect
include "helpers.nim"
export tables

# ── Constants, lets, vars ──
const ReorderPoint = 25
const Names = ["north", "south", "east"]
const Lookup = {"a": 1, "b": 2}.toTable
let immutable = 10
var mutable = 20
var a, b, c: int
let (first, second) = (1, 2)
let tuple3 = (x: 1, y: 2.5, z: "three")

# ── Numbers ──
let dec = 1_000_000
let hex = 0xFF_EC
let oct = 0o755
let bin = 0b1010_1010
let flt = 3.14_15
let expo = 1.5e-10
let i8 = 127'i8
let i16 = 1'i16
let i32 = 1'i32
let i64 = 1'i64
let u8 = 255'u8
let u64 = 1'u64
let f32 = 1.5'f32
let f64 = 1.5'f64
let uz = 5'u
let inf = Inf
let negInf = -Inf
let nan = NaN

# ── Strings and characters ──
let plain = "tab:\t newline:\n quote:\" backslash:\\ hex:\x41 unicode:\u00e9 \u{1F4E6} oct:\101 bell:\a esc:\e"
let raw = r"C:\path\no\escapes ""quoted"" inside"
let triple = """
A triple-quoted string with "quotes" and
no escape processing: \n stays literal.
"""
let generalized = fmt"qty={mutable} total={mutable * 2:>8.2f}"
let amp = &"sku {first} has {second + 1} left"
let rawFmt = fmt"{{braces}} and {immutable}"
let ch = 'a'
let chEsc = '\n'
let chHex = '\x41'

# ── Types ──
type
  Zone = enum
    Cold, Dry, Hazard = 5

  Item = object
    sku: string
    qty: int
    price: float
    zone*: Zone

  Pair[T] = tuple[first, second: T]
  Stack[T] = ref object
    items: seq[T]
  Handler = proc (x: int): int {.closure.}
  Index = distinct int
  Weekday = range[1..7]
  Flags = set[Zone]
  Shape = ref object of RootObj
  Circle = ref object of Shape
    radius: float
  Node = ref object
    case kind: Zone
    of Cold: coldTemp: float
    of Dry: discard
    else: label: string
  Money = float
  Matrix = array[0..2, array[0..2, float]]

# ── Procs, funcs, methods, converters ──
proc lowStock(items: seq[Item]): seq[Item] =
  ## Items at or below the reorder point, cheapest first.
  result = items.filterIt(it.qty <= ReorderPoint)
  result.sort(proc(a, b: Item): int = cmp(a.price, b.price))

func square(x: int): int = x * x

proc greet(name: string; greeting = "hello"; punctuation = '!'): string =
  result = greeting & ", " & name & $punctuation

proc sum(xs: varargs[int]): int =
  for x in xs: result += x

proc swapIt[T](a, b: var T) =
  let tmp = a
  a = b
  b = tmp

proc `+`(a, b: Item): Item = Item(sku: a.sku, qty: a.qty + b.qty, price: a.price)
proc `$`(i: Item): string = i.sku & ":" & $i.qty
proc `[]`(s: Stack[int]; i: int): int = s.items[i]
proc `==`(a, b: Item): bool = a.sku == b.sku

method area(s: Shape): float {.base.} = 0.0
method area(c: Circle): float = PI * c.radius * c.radius

converter toMoney(x: int): Money = x.float

proc fetch(url: string): Future[string] {.async.} =
  await sleepAsync(10)
  return "ok"

proc risky() {.raises: [IOError, ValueError].} =
  raise newException(ValueError, "bad input")

# ── Iterators, templates, macros ──
iterator described(items: seq[Item]): string =
  for it in items:
    yield (if it.qty == 0: &"{it.sku}: out of stock" else: &"{it.sku}: {it.qty} left")

iterator countTo(n: int): int =
  var i = 0
  while i <= n:
    yield i
    inc i

template timeIt(name: string, body: untyped) =
  let start = cpuTime()
  body
  echo name, " took ", cpuTime() - start, "s"

macro dumpAst(body: untyped): untyped =
  echo body.treeRepr
  result = body

# ── Control flow ──
proc classify(n: int): string =
  if n < 0: "negative"
  elif n == 0: "zero"
  else: "positive"

proc flow() =
  let x = 5
  case x
  of 1, 2, 3: echo "small"
  of 4..10: echo "medium"
  else: echo "large"

  for i in 0 ..< 3: echo i
  for i in countdown(5, 1): echo i
  for i, v in @[10, 20, 30]: echo i, v
  for k, v in {"a": 1}.toTable: echo k, v
  var n = 0
  while n < 5:
    inc n
    if n == 2: continue
    if n == 4: break
  block named:
    for i in 0 .. 3:
      for j in 0 .. 3:
        if i * j > 4: break named
  when defined(windows):
    echo "win"
  elif defined(macosx):
    echo "mac"
  else:
    echo "other"
  try:
    risky()
  except ValueError as e:
    echo "caught ", e.msg
  except IOError, OSError:
    echo "io"
  except:
    echo "any"
  finally:
    echo "done"
  defer: echo "leaving"
  let r = if x > 3: "big" else: "small"
  let t = case x of 1: "one" else: "many"
  discard r & t

# ── Operators and expressions ──
let ops = (1 + 2 - 3) * 4 div 2 mod 3
let fl = 7 / 2
let bits = (0xF0 and 0x3C) or (1 shl 4) xor (256 shr 2)
let neg = not true
let logic = (a == b) and (a != b) or (a < b) and not (a >= b)
let isIn = 3 in [1, 2, 3]
let notIn = 5 notin [1, 2, 3]
let isOf = Shape(Circle()) of Circle
let isNot = 1 isnot string
let concat = "a" & "b" & 'c'
let slice = "hello"[1 .. ^2]
let slice2 = @[1, 2, 3, 4][1 ..< 3]
let addr0 = addr mutable
let sq = @[1, 2, 3].map(x => x * x)
let sqs = collect(newSeq): (for i in 1 .. 5: i * i)
let opt = some(5)
let dotted = "a b c".split(' ').mapIt(it.toUpperAscii)
mutable += 1
mutable -= 1
mutable *= 2
mutable = mutable.succ
mutable.inc
a = `+`(1, 2)

# ── Pragmas and assert ──
when isMainModule:
  assert square(3) == 9, "square works"
  doAssert greet("world") == "hello, world!"
  let items = @[Item(sku: "A-100", qty: 12, price: 4.5), Item(sku: "C-300", qty: 3, price: 99.0)]
  for line in described(lowStock(items)):
    echo line
  echo &"value: {items.mapIt(it.qty.float * it.price).foldl(a + b):.2f}"
  timeIt "loop":
    for i in countTo(3): discard i
  static: echo "compile time"
  {.emit: "/* raw C */".}
  var cstr {.importc: "getenv", header: "<stdlib.h>".}: cstring

# ── More Nim: concepts, generics, pragmas, templates, asm and more ──
type
  Comparable = concept x, y
    (x < y) is bool
  Printable = concept x
    $x is string
  Container[T] = concept c
    c.len is Natural
    c[0] is T
  Ordinal2 = enum a, b, c
  Fruit {.pure.} = enum Apple, Pear
  Obj = object {.packed.}
    x: int8
    y: int32
  RefObj = ref object of RootObj
    id: int
  Gen[T; N: static[int]] = object
    data: array[N, T]
  Callback2 = proc (x: int) {.nimcall, gcsafe.}
  PtrT = ptr int
  Fn = proc (a: int): int {.closure, noSideEffect.}
  Either[A, B] = object
    case isLeft: bool
    of true: left: A
    of false: right: B

proc maxOf[T: Comparable](a, b: T): T = (if a < b: b else: a)
proc show(x: Printable): string = $x
proc total[T](c: Container[T]): int = c.len
proc typed(x: typedesc[int]): string = "int"
proc staticArg(n: static int): int = n * 2
proc untypedArg(body: untyped) = body
proc varArg(x: var int; y: out int) = y = x
proc lentArg(s: lent string): lent string = s
proc sinkArg(s: sink string) = discard s
proc ownedArg(x: owned RefObj) = discard
proc castDemo(x: pointer): int = cast[int](x)
proc unsafeAddr0(x: var int): ptr int = unsafeAddr x
proc noReturn() {.noreturn.} = quit(1)
proc inl() {.inline, raises: [], tags: [], forbids: [].} = discard
proc exported*(x: int): int {.exportc: "exported_c", dynlib, cdecl.} = x
proc imported(x: cint): cint {.importc: "abs", header: "<stdlib.h>".}
proc emitter() {.compileTime.} = discard
proc deprecatedP() {.deprecated: "use exported".} = discard
proc threadP() {.thread.} = discard
proc locks() {.locks: 0.} = discard

template unrollIt(n: static int, body: untyped) =
  for i in 0 ..< n:
    body
template withLock(l: var int, body: untyped) =
  l = 1
  try: body
  finally: l = 0
template declareVar(name: untyped, value: typed) =
  var name = value
template `!=`(a, b: untyped): untyped = not (a == b)

macro mkProc(name: static string): untyped =
  result = newStmtList()
  result.add quote do:
    proc `name`*(): int = 42

macro stringify(arg: untyped): string = newLit(arg.repr)
dumpTree:
  echo "tree"

# Statement forms
bind show
mixin `$`
using self: RefObj
static:
  const compileTimeVal = 5
var x2 {.global.} = 0
let unused {.used.} = 1
var th {.threadvar.}: int
const csv = staticRead("data.csv")
const ver = gorge("echo 1")
const (q1, q2) = (1, 2)
discard parseInt("5")
doAssert not compiles(undeclared)
echo declared(x2), defined(release), sizeof(int), typeof(1), type(1), high(int), low(int8), ord('a'), chr(97)
echo $(1 + 2), repr(@[1]), len("abc"), contains("abc", 'a'), 5 in {1, 5}, 'x' in {'a' .. 'z'}
echo {1, 2, 3} * {2} + {4} - {1}, {1} <= {1, 2}
echo [1, 2, 3].len, (1, "a")[0], @[1, 2][^1], "abc"[0 ..< ^1], [1, 2, 3][1 .. 2]
echo 1 shl 3 shr 1, 5 and 3, 5 or 3, 5 xor 3, not 5, 7 div 2, 7 mod 2, 2 ^ 8
echo 1.0 / 3.0, 1'f32 + 2'f32, 'a' < 'b', "a" < "b", true and false or not true, 1 == 1
echo (when true: 1 else: 2), (if true: 1 else: 2), (case 1 of 1: "a" else: "b")
echo `+`(1, 2), 1.`+`(2), "a" & "b" & $5, @[1] & @[2], 'a' & "b"
echo -1.abs, +1, -(-1), 5.0.int, 5.float, int('a'), string(5.cstring), cstring("x"), pointer(nil).isNil

asm """
  nop
"""

block labeled:
  discard
  break labeled

proc iterDemo(): int =
  iterator inner(): int {.closure.} = yield 1
  for v in inner(): result += v
  var fn = inner
  result += fn()

var lazyVal = block: 5
var arr2 = [1, 2, 3]
var seq2 = @[1, 2, 3]
var tab = {"a": 1}.toTable
var tup2: tuple[a: int, b: string] = (a: 1, b: "x")
var setv: set[char] = {'a', 'b'}
var opt2 = none(int)
var fnv: proc (): int = proc (): int = 5
var cnt = 0
for i in 0 .. 2: cnt += i
for i, c in "abc": cnt += i + ord(c)
for a, b in zip([1, 2], [3, 4]): cnt += a * b
for i in countup(0, 10, 2): cnt += i
for s in items(["a"]): cnt += s.len
for k in keys(tab): cnt += k.len
for x in pairs(@[1]): cnt += x[0]
while true: break
if cnt > 0 and cnt < 100 or cnt == 5: discard
elif cnt != 3: discard
else: discard
when not defined(js) and (defined(linux) or defined(macosx)): discard
case cnt
of 0: discard
of 1 .. 5, 10: discard
of 6, 7: discard
else: discard
try:
  raise newException(IOError, "x")
except IOError, ValueError:
  discard
except Exception as e:
  echo e.msg, e.getStackTrace()
else:
  discard
finally:
  discard

##[
  A multi-line documentation comment (Nim 2).
  It may span lines and contain ``code``.
]##

# ── Imports: every form ──
import std/strutils except toUpperAscii
import std/[tables as tbl, sets]
import pkg/[chronos, results]
from std/os import nil
from std/times import Duration, initDuration
import std/sequtils as sq
import "mod with spaces" as spaced
export strutils except join

# ── Experimental switches and global pragmas ──
{.experimental: "strictDefs".}
{.experimental: "strictFuncs".}
{.experimental: "views".}
{.experimental: "dotOperators".}
{.push inline, checks: off.}
proc fastAdd(a, b: int): int = a + b
{.pop.}
{.warning: "this is a user warning".}
{.hint: "this is a user hint".}
{.passC: "-O2".}
{.passL: "-lm".}
{.compile: "helper.c".}
{.link: "libx.a".}
{.pragma: myCdecl, cdecl, exportc.}
{.deadCodeElim: on.}

# ── Enums with string values, ordinals and pure enums ──
type
  Color = enum
    Red = "red"
    Green = "green"
    Blue = (3, "blue")
  Dir {.pure.} = enum North, East, South, West
  Level = enum lo = 1, mid = 5, hi = 10
  Bits {.size: 4.} = enum b0, b1
  Packed {.packed.} = object
    flag {.bitsize: 3.}: cint
    rest {.bitsize: 5.}: cint
  U = object {.union.}
    i: int32
    f: float32
  Req {.requiresInit.} = object
    id: int
  ByRef {.byref.} = object
    v: int
  Aligned {.align: 16.} = object
    data: array[4, float32]
  Natural2 = Natural
  Pos = Positive
  Vec2[T: SomeNumber] = object
    x, y: T
  OptRef = ref int not nil
  Proc3 = proc (a: int, b: string): bool {.noSideEffect, raises: [].}
  Arr = array[Dir, int]
  OpenA = openArray[int]
  Ptr2 = ptr UncheckedArray[byte]
  Tup = tuple[a: int, b: string]
  Either2 = int | string
  NotNil = not nil
  SeqOf[T] = seq[T]

# ── Lifecycle hooks (Nim 2) ──
type Handle = object
  fd: int
proc `=destroy`(h: Handle) = discard h.fd
proc `=copy`(dst: var Handle; src: Handle) {.error.}
proc `=sink`(dst: var Handle; src: Handle) = dst.fd = src.fd
proc `=wasMoved`(h: var Handle) = h.fd = -1
proc `=dup`(h: Handle): Handle = Handle(fd: h.fd)
proc `=trace`(h: var Handle; env: pointer) = discard
proc `=init`(h: out Handle) = h.fd = 0

# ── Custom operators, dot-calls, command syntax and sugar ──
proc `|>`[T, U](x: T; f: proc (a: T): U): U = f(x)
proc `.`(o: Handle; field: string): int = 0
proc `.=`(o: var Handle; field: string; v: int) = discard
proc `[]=`(o: var Vec2[int]; i: int; v: int) = discard
proc `{}`(o: Vec2[int]; i: int): int = 0
proc `<=>`(a, b: int): int = cmp(a, b)
proc `%%`(a, b: int): int = a mod b
proc `@@`(x: int): int = x
proc `∘`(a, b: int): int = a + b
proc `and`(a, b: Req): bool = true
proc `$`(c: Color): string = $ord(c)
proc `<`(a, b: Req): bool = a.id < b.id
proc `-`(v: Vec2[int]): Vec2[int] = Vec2[int](x: -v.x, y: -v.y)
proc `+=`(v: var Vec2[int]; o: Vec2[int]) = v.x += o.x; v.y += o.y
echo 1 |> (x => x + 1)
echo "a,b".split(',').len, "x".repeat(3), "abc".len, "%s" % ["a"], "$1" % "x"
echo(1, 2, 3)
echo 5.toHex(4), 5.addr.repr, @[1].len
let sugar: (int) -> int = x => x * 2
let lam = proc (x: int): int = x + 1
let lam2 = proc (x, y: int): int {.closure.} = x * y
let lam3 = func (x: int): int = x
let doBlock = sq.map(@[1, 2], proc (x: int): int = x * 2)
proc withDo(f: proc (x: int): int) = discard f(1)
withDo do (x: int) -> int:
  x + 1
proc withBody(body: proc ()) = body()
withBody:
  echo "body"
let `type` = 5
let `my var` = 6
var semi = 1; var colon = 2
let multi = [
  1, 2,
  3, 4]
let longExpr = 1 +
  2 +
  3
let tupleSugar = (a: 1, b: "x")
let (ta, tb) = tupleSugar
let (_, onlyB) = (1, 2)
var x3, y3, z3 = 0
let nested = @[@[1, 2], @[3]]
let table = {1: "a", 2: "b"}.toTable
let strTab = {"k": @[1]}.toTable
let arr3: array[3, int] = [1, 2, 3]
let arrIdx = [Red: 1, Green: 2, Blue: 3]
let chars = {'a'..'z', '0'..'9'}
let setOfDir: set[Dir] = {North, South}
let nilRef: ref int = nil
let ptrCast = cast[ptr int](nil)
let backslash = "a\\b\q\z"
let fmtDemo = fmt"{3.14159:.2f} {42:05} {x3:>8} {\"q\"}"
let bracketed = @[1, 2, 3][0 .. ^1]
let bounded = @[1, 2, 3][^2 .. ^1]
let hexChars = "\x41\u0042\U00000043"
let ops2 = 1 ..< 3
let ops3 = 1 .. 3
let ops4 = a..b
let neg3 = -1
let pos3 = +1
let sizes = (sizeof(int), alignof(int), offsetOf(Packed, rest))

# ── Statements ──
proc ctrl(n: int): int =
  if n > 0: return 1
  elif n < 0: return -1
  result = 0
  # `while` / `for` with labels, `continue`, `break`
  block outer:
    var i = 0
    while true:
      inc i
      if i > 3: break outer
  for i in 0 ..< n:
    if i == 2: continue
  # pattern: case with ranges, sets and strings
  case "abc"
  of "a", "b": discard
  of "abc": discard
  else: discard
  case n
  of 0 .. 9: discard
  of 10, 20, 30: discard
  else: discard
  # try/except/else/finally and raise
  try:
    raise newException(ValueError, "x")
  except ValueError as e:
    discard e
  except:
    raise
  else:
    discard
  finally:
    discard
  # defer and when/elif
  defer:
    discard
  when sizeof(int) == 8: discard
  elif sizeof(int) == 4: discard
  else: discard
  # yield inside iterators, discard of values
  discard n
  # assignment forms
  var v = 1
  v = 2
  v += 1
  v -= 1
  v *= 2
  v = v div 2
  (v, result) = (result, v)
  # static and const blocks
  const k = block:
    var t = 0
    for i in 0 .. 3: t += i
    t
  static:
    discard k

# ── Generics, concepts, templates, macros: extra forms ──
proc genericFn[T, U](a: T; b: U): (T, U) = (a, b)
proc constrained[T: int | float](a: T): T = a
proc withStatic[N: static int](a: array[N, int]): int = N
proc defaultT[T = int](x: T): T = x
iterator pairsOf[T](s: seq[T]): (int, T) =
  for i, v in s: yield (i, v)
iterator fwd(): int {.inline.} =
  yield 1
template tmpl(a: int; b: untyped = 0): untyped = a + b
template dirty() {.dirty.} = discard injectedName
template tmplWithBlock(body: untyped): untyped = body
macro mac(args: varargs[untyped]): untyped =
  result = newStmtList()
  for a in args: result.add a
macro withTyped(x: typed): untyped = x
macro buildTypes(): untyped =
  quote do:
    type Gen1 = object
      a: int
macro pragmaMacro(x: untyped): untyped {.deprecated.} = x
proc annotated() {.pragmaMacro.} = discard
proc customPragma() {.myCdecl.} = discard
let genericCall = genericFn[int, string](1, "a")
let explicit = constrained[float](1.5)
