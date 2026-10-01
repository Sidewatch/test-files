#!/usr/bin/env nim r
## Nim showcase: a typed inventory with procs, iterators, templates and macros.
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
