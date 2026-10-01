#!/usr/bin/env coffee
# Warehouse inventory in CoffeeScript.
# A hash starts a line comment. TODO: port the report to async/await.

###
A block comment.
It is kept in the generated JavaScript.
@license MIT
###

# ── Literals ──────────────────────────────────────────────────────────
nothing = null
unset   = undefined
yes_    = yes
no_     = no
on_     = on
off_    = off
truth   = true
falsity = false

int      = 42
negative = -7
float    = 3.14159
exponent = 1.5e-3
hex      = 0xFF
octal    = 0o755
binary   = 0b1010
big      = 1_000_000
infinite = Infinity
notnum   = NaN

# ── Strings ───────────────────────────────────────────────────────────
single  = 'single quoted, no #{interpolation}, escape \' and \\'
double  = "double quoted with #{int * 2} interpolation and \t tab \n newline é \x41"
nested  = "outer #{ "inner #{int}" } done"
multi   = "A multi-line
           string joined with spaces"
heredoc = """
  Block string with #{int} interpolation
    and preserved relative indentation
  and "quotes" inside
  """
rawhere = '''
  Single-quoted block, no #{interpolation}
  '''
joined  = 'a' + 'b' + "c"

# ── Regular expressions ───────────────────────────────────────────────
skuPattern = /^[A-Z]-\d{3}$/gi
division   = a / b / c
blockRegex = ///
  ^ (\w+)      # the word
  \s*          # optional space
  (\d+)        # the number
  $
///imgu

# ── Collections ───────────────────────────────────────────────────────
list   = [1, 2, 3, 4, 5]
mixed  = [1, 'two', 3.0, [4, 5], {six: 6}]
multi  = [
  1, 2, 3
  4, 5, 6
]
range1 = [1..5]
range2 = [1...5]
rangeR = [5..1]
slice1 = list[1..3]
slice2 = list[1...-1]
slice3 = list[..2]
slice4 = list[2..]
item   = {sku: 'A-100', qty: 12, price: 4.5}
braces = { a: 1, b: 2 }
implicit =
  name: 'Widget'
  tags: ['fragile', 'blue']
  dims:
    width: 10
    height: 20
shorthand = {int, float, hex}
quotedKey = {'quoted-key': 1, "other key": 2, 3: 'numeric'}
computed  = {"#{int}": 'dynamic key'}

# ── Operators ─────────────────────────────────────────────────────────
sum   = 1 + 2 - 3 * 4 / 5 % 6
power = 2 ** 8
floor = 7 // 2
mod   = -7 %% 3
inc   = int++
dec   = --int
logic = (a and b) or (c && d) or not e
cmp   = a is b or a isnt b or a == b or a != b or a < b or a >= b
ident = a is not b
bits  = (a & b) | (a ^ b) | ~a
shift = a << 2 >> 1 >>> 1
exist = a?
safe  = a?.b?.c
safeCall = fn?(1, 2)
safeIdx  = list?[0]
default1 = a ? 'default'
assign1 ?= 5
assign2 ||= 6
assign3 &&= 7
assign4 += 1
assign5 -= 1
assign6 *= 2
assign7 /= 2
assign8 %= 3
assign9 **= 2
assignA //= 2
assignB <<= 1
assignC |= 1
assignD or= 2
assignE and= 3
membership = 3 in list
absence    = 'x' of item
notIn      = 3 not in list
notOf      = 'x' not of item
instance   = item instanceof Object
kind       = typeof item
removal    = delete item.qty
newObj     = new Date()
newNoParen = new Date

# ── Functions ─────────────────────────────────────────────────────────
square  = (x) -> x * x
fat     = (x) => x * 2
noArgs  = -> 42
empty   = ->
defaults = (name = 'guest', greeting = "Hello, #{name}") -> "#{greeting}!"
splat   = (first, rest...) -> rest.length
middle  = (first, middle..., last) -> middle
destruct = ({sku, qty = 0}, [a, b]) -> "#{sku}: #{qty} #{a}#{b}"
thisArg = (@sku, @qty) -> @total = @sku + @qty
multiLine = (x) ->
  y = x * 2
  y + 1
callSplat = fn args...
callArr   = fn [1, 2]...
implicitCall = console.log 'implicit call', 1, 2
chained = list.map((x) -> x * 2).filter (x) -> x > 2
iife = do -> 42
iifeArg = do (x = 1) -> x + 1
generator = ->
  yield 1
  yield from [2, 3]
  return
asyncFn = ->
  result = await fetch 'https://example.com'
  await result.json()
backtick = `function legacy() { return 1; }`

# ── Classes ───────────────────────────────────────────────────────────
class Emitter
  handlers: {}
  @registry: []
  @create: (args...) -> new this args...

  constructor: -> @handlers = {}

  on: (event, fn) ->
    (@handlers[event] ?= []).push fn
    this

  emit: (event, args...) ->
    fn args... for fn in @handlers[event] ? []
    return

class Item extends Emitter
  constructor: (@sku, @qty = 0) ->
    super()
    @tags = []

  restock: (amount) =>
    @qty += amount
    @emit 'restock', @qty
    super

  toString: -> "Item(#{@sku}, #{@qty})"

  Object.defineProperty @prototype, 'low', get: -> @qty < 25

  isLow: -> @qty < 25
  @helper: -> 'static'
  ::proto = 'prototype shorthand'

class Counter extends Emitter
  constructor: (@limit = 3) ->
    super()
    @count = 0

  tick: =>
    @count += 1
    @emit 'tick', @count
    @emit 'done' if @count >= @limit

# ── Control flow ──────────────────────────────────────────────────────
if int > 10
  console.log 'big'
else if int > 5
  console.log 'medium'
else
  console.log 'small'

console.log 'postfix if' if int
console.log 'postfix unless' unless int
unless int then console.log 'none'
label = if int > 3 then 'high' else 'low'
result = switch int
  when 1, 2 then 'few'
  when 3
    'three'
  else 'many'

switch
  when int < 0 then 'negative'
  else 'non-negative'

i = 0
while i < 3
  i++
until i is 0
  i--
loop
  break
console.log i while i-- > 0

for x in list
  continue if x is 2
  break if x > 4
  console.log x
for x, idx in list by 2
  console.log idx, x
for key, value of item
  console.log key, value
for own key of item
  console.log key
for [a, b] in [[1, 2], [3, 4]]
  console.log a + b
for x in [1..3] when x isnt 2
  console.log x
squares = (x * x for x in [1..5] when x % 2 is 1)
evens   = (x for x in list when x % 2 is 0)
pairs   = ([k, v] for k, v of item)
console.log x for x in list

# ── Errors ────────────────────────────────────────────────────────────
try
  throw new Error 'boom'
catch err
  console.error err.message
finally
  console.log 'cleanup'

try risky()
catch then recover()

# ── Destructuring and modules ─────────────────────────────────────────
{sku, qty} = item
{sku: renamed, dims: {width}} = implicit
[first, second, rest...] = list
[a, b] = [b, a]
{@sku, @qty} = item
import fs from 'fs'
import {readFile, writeFile as write} from 'fs/promises'
import * as path from 'path'
import defaultExport, {named} from './module'
export default class Warehouse
export {square, fat}
export fnExported = -> 1
export * from './other'

# ── Embedded JavaScript and misc ──────────────────────────────────────
embedded = `Math.max(1, 2)`
assert = (cond) -> throw new Error 'failed' unless cond
debugger
counter = new Counter 2
counter
  .on 'tick', (n) -> console.log "tick ##{n}"
  .on 'done', -> console.log 'finished'

counter.tick() for [1..2]

# ── Further constructs ────────────────────────────────────────────────
# Operators and keywords not yet shown
unlessThen = 1 unless 0
untilLoop  = (i-- until i is 0)
whenThen   = switch x when 1 then 'one' else 'many'
aliased    = a isnt b and c is d or not e
reservedAliases = [yes, no, on, off, undefined, null, true, false]
chain      = a?.b?[c]?(d)
splatCall  = Math.max [1, 2, 3]...
objSplat   = {a, b, rest...} = obj
arrSplat   = [head, middle..., tail] = list
nestedDestructure = {a: {b: [c, d]}} = deep
computedKeys = {"#{prefix}_key": 1, [expr()]: 2}
fn1 = (a, b = a * 2, {c, d} = {}, [e, f] = [], g...) ->
bound = (x) => @value + x
generatorFn = -> yield* other()
asyncGen = ->
  for await x from stream
    yield x
awaitAll = -> await Promise.all [p1, p2]
withTry = -> try await risky() catch e then null
exponent = 2 ** 3 ** 2
floorDiv = 7 // 2
modulo   = -7 %% 3
bitops   = (a & b) | (a ^ b) | ~a << 2 >> 1 >>> 1
existential = a ? b ? c
existAssign = a ?= b
safeDelete = delete a?.b
instanceTest = x instanceof Array
typeTest = typeof x is 'string'
inRange = 3 in [1..5]
spreadRange = [1..3]...
stringRange = ['a'..'e']
backtickRegex = `/\d+/g`
extendsKeyword = class A extends (B ? Object)
mixin = (base, mixins...) -> base::[k] = v for k, v of m for m in mixins
prototype = Array::slice
thisShortcut = @
thisProp = @prop
thisCall = @method()
staticThis = @::
superCall = -> super
superArgs = -> super arg1, arg2
newTarget = new.target
importMeta = import.meta.url
dynamicImport = import('./mod')

# Interpolation edge cases
"#{a}#{b}" + '#{not interpolated}' + "\#{escaped}" + "nested #{ "deep #{ "deeper #{x}" }" }"
"#{x + 1} #{fn(a, b)} #{obj.key} #{list[0]} #{if y then 'a' else 'b'}"
"""
heredoc with #{x} and "double" and 'single' and \#{escaped}
  keeps indentation
"""
'''
single heredoc #{x} stays raw
'''

# Regex heredoc with interpolation and flags
pattern = ///
  ^ #{prefix}        # interpolated
  [a-z]+             # letters
  (?: \d{2,3} )?     # optional digits
  $
///gimsuy

# Block comments in odd places
###
  Another block comment
  with ### inside? no, ends at the first triple-hash.
###
x = 1 ### inline block comment ### + 2

# Line continuations and indentation forms
longCall = fn arg1,
  arg2,
  arg3
longChain = list
  .filter (x) -> x?
  .map    (x) -> x * 2
  .reduce ((a, b) -> a + b), 0
condition = a and
  b and
  c
ifBlock = if a
  1
else if b
  2
else
  3
implicitObjects = fn
  key: 'value'
  other:
    deep: true
implicitArrays = fn [
  1
  2
]
trailingCommas = [
  1,
  2,
]
semicolons = (a = 1; b = 2; a + b)
oneLiner = if a then b else c
wrapped = (
  if a
    1
  else
    2
)

# Class features
class Base
  @staticProp: 1
  instanceProp: 2
  'quoted method': -> 'quoted'
  "interpolated #{name} method": -> 'dynamic'
  get_value: -> @value
  set_value: (@value) -> this
  constructor: (@value = 0) ->
  toString: -> "Base(#{@value})"
  @::extra = -> 'prototype'

class Derived extends Base
  constructor: ->
    super
    @derived = true
  toString: -> "Derived/" + super()

mixed = new (class extends Base)

# Switch forms and comprehension forms
switch typeof x
  when 'string', 'number'
    console.log 'primitive'
  when 'object'
    console.log 'object'
  else
    console.log 'other'

result = for x in [1..3]
  x * 2
nested = ([x, y] for x in [1..2] for y in [3..4])
withGuard = (x for x in list when x > 1 and x < 5)
withIndex = (i + x for x, i in list)
byStep = (x for x in [0..10] by 2)
overObject = (k + v for own k, v of obj when v?)
whileExpr = (x-- while x > 0)

# Modules and exports in all forms
export default -> 1
export class Exported
export { a as b, c as default }
export { x } from './y'
export * as ns from './z'
import 'side-effects'
import * as all from 'lib'
import def, * as ns2 from 'lib'
import { a as aa, default as dd } from 'lib'

# Debugger statement, throw expression, assert-like
debugger
throw new Error "unreachable" unless true
# TODO: replace the callback pyramids with async/await.
