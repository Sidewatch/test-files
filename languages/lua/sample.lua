#!/usr/bin/env lua
-- Lua 5.5 — syntax showcase (lua is not installed here; written against the 5.5 reference manual)
-- ── Comments ──
-- Line comment. TODO: cache the totals. FIXME: handle negative stock.
--[[ Block comment
     spanning multiple lines ]]
--[=[ Level-1 block comment containing ]] inside ]=]
--[==[ Level-2 ]==]
---@class Item  -- LuaLS annotation
---@field sku string
---@param name string The name
---@return number total

-- ── Locals, constants, numbers ──
local MAX_BINS <const> = 1000
local handle <close> = setmetatable({}, { __close = function() end })
local integer, negative = 42, -17
local float, exponent, small = 3.14159, 6.022e23, 1e-9
local hex, hexfloat, hexexp = 0xFF, 0x1.8p3, 0xA.8p0
local huge, tiny = math.huge, -math.huge
local nan = 0/0
local truthy, falsy, nothing = true, false, nil
local big = 9007199254740993
local leading_dot, trailing_dot = .5, 5.

-- ── Strings ──
local single = 'It\'s a "pallet"'
local double = "Tab\t newline\n quote \" backslash \\ bell\a bs\b ff\f cr\r vt\v"
local numeric = "\65\066\x41\u{48}\u{1F4E6} z-skip: \z
                 continued line"
local multi = [[
First line "quoted" with \n not an escape
Second line]]
local level = [==[
Contains ]] and [[ nested brackets ]==]
local unicode = "Zürich → 東京 ✓"
local concat = "Item " .. integer .. " of " .. #unicode

-- ── Tables ──
local item = { sku = "A-100", quantity = 5, ["quoted key"] = true, [1] = "one", [2 + 3] = "five" }
local list = { 1, 2, 3, nested = { a = { b = { c = "deep" } } }, "mixed"; "semicolon" }
local empty = {}
local matrix = { { 1, 2 }, { 3, 4 } }
print(item.sku, item["sku"], list[1], list.nested.a.b.c, matrix[2][1], #list)

-- ── Operators ──
local arith = 7 + 3 - 2 * 4 / 5 % 3 ^ 2
local floordiv = 7 // 2
local bitwise = (5 & 3) | (5 ~ 3) << 1 >> 1
local bitnot = ~5
local cmp = 1 < 2 and 2 <= 3 or 3 > 4 and 4 >= 5 and 5 == 5 and 5 ~= 6
local logic = not (true and false) or nil
local length = #"hello" + #list
local ternary = (arith > 0) and "positive" or "non-positive"

-- ── Functions ──
local function add(a, b)
  return a + b
end

function global_function(...)
  local args = { ... }
  local count = select("#", ...)
  return count, table.unpack(args)
end

local Vector2 = {}
Vector2.__index = Vector2

function Vector2.new(x, y)
  local self = setmetatable({}, Vector2)
  self.x = x or 0
  self.y = y or 0
  return self
end

function Vector2:magnitude()
  return math.sqrt(self.x * self.x + self.y * self.y)
end

function Vector2.__add(a, b) return Vector2.new(a.x + b.x, a.y + b.y) end
function Vector2.__eq(a, b) return a.x == b.x and a.y == b.y end
function Vector2.__tostring(v) return string.format("(%g, %g)", v.x, v.y) end
Vector2.__lt = function(a, b) return a:magnitude() < b:magnitude() end
Vector2.__len = function() return 2 end
Vector2.__call = function(self, k) return self[k] end
Vector2.__concat = function(a, b) return tostring(a) .. tostring(b) end

local anonymous = function(x) return x * 2 end
local curried = function(a) return function(b) return a + b end end
print(add(1, 2), anonymous(4), curried(1)(2), #Vector2.new(3, 4).x .. "")

-- ── Control flow ──
local n = 10
if n > 5 then
  print("big")
elseif n > 2 then
  print("medium")
else
  print("small")
end

for i = 1, 10, 2 do
  if i == 5 then goto continue end
  if i > 8 then break end
  print(i)
  ::continue::
end

for i = 10, 1, -1 do end
for key, value in pairs(item) do print(key, value) end
for index, value in ipairs(list) do print(index, value) end
for word in string.gmatch("a b c", "%a+") do print(word) end

local count = 0
while count < 3 do count = count + 1 end
repeat count = count - 1 until count <= 0

do
  local scoped = "inside"
end

-- ── Error handling and coroutines ──
local ok, err = pcall(function() error({ code = 42 }) end)
local ok2, err2 = xpcall(function() error("boom", 2) end, debug.traceback)
assert(ok == false, "pcall should fail")

local co = coroutine.create(function(a)
  local b = coroutine.yield(a + 1)
  return b * 2
end)
print(coroutine.resume(co, 1))
print(coroutine.resume(co, 10))
local wrapped = coroutine.wrap(function() for i = 1, 3 do coroutine.yield(i) end end)

-- ── Patterns and the standard library ──
local s = "SKU-1234 qty=56"
print(s:match("^(%u+)%-(%d+)"), s:find("qty=(%d+)"), s:gsub("%d", "#"), s:rep(2, ","), s:sub(-2), s:upper(), s:byte(1))
print(string.format("%5.2f|%-8s|%d|%x|%q|%s", 3.14159, "ab", 42, 255, "q\n", tostring(nil)))
print(("%s=%s"):format("k", "v"), ("x"):rep(3), #("abc"))
table.insert(list, "tail"); table.sort(list, function(a, b) return tostring(a) < tostring(b) end)
print(table.concat({ "a", "b" }, ", "), os.time(), os.date("%Y-%m-%d"), math.floor(3.7), math.max(1, 2), math.pi)
print(type(nil), type(print), type({}), rawequal(list, list), rawlen(list), next(item), tostring(1e15), tonumber("0x10"), tonumber("10", 2))

-- ── Modules ──
local json = require("json")
local ok3, lfs = pcall(require, "lfs")
package.path = package.path .. ";./?.lua"
print(_VERSION, _G._VERSION, _ENV == _G, arg and arg[0])

-- ── Rare constructs ──
---@alias Sku string
---@type table<string, number>
---@generic T
---@overload fun(a: number): number
---@vararg any
---@see Vector2
---@deprecated
---@diagnostic disable-next-line: unused-local
--- Triple-dash doc comment line
--[==[ level-2 long comment
]] and ]=] do not close it ]==]
--[[ unterminated-looking on one line ]] local after_block = 1 -- code after a block comment

-- number forms
local numbers_more = {
  0x.1p4, 0xA.8p-1, 0X1P+2, 0xffffffffffffffff, 9223372036854775807, 9223372036854775808,
  1e2, 1E+2, 1e-2, .5e1, 5.e1, 3., 0x10, 0XaBc, 08, 1 // 1, 3 | 4, 0xe+1,
}

-- string escapes
local escapes_more = {
  "\a\b\f\n\r\t\v\\\"\'", '\65\066\0067', "\x41\x4a", "\u{41}\u{7FFFFFFF}\u{10FFFF}", "a\z
      b", "line1\
line2", 'single \' and "double"', "double \" and 'single'", [[
leading newline skipped]], [=[with ]] inside]=], [==[
]==],
}

-- calls without parentheses
print "string call"
print 'single'
print [[long call]]
print [==[leveled long call]==]
local call_table = setmetatable {} { __index = function() end }
local t_call = type {}
require "json"
local chained = ("x"):rep(2):upper():lower():len()
local method_on_literal = ("%d"):format(5)
local index_call = (function() return { f = function() return 1 end } end)().f()

-- nested names and method definitions
local obj = { a = { b = { c = {} } } }
function obj.a.b.c.fn(x) return x end
function obj.a.b.c:method(x) return self, x end
function obj.a.b:other() end
obj.a.b.c.anon = function(...) return select("#", ...), ... end
obj["a"]["b"].c["d e"] = { [1.5] = "float key", [true] = "bool key", [print] = "function key", [-1] = "neg", [0x10] = "hex" }

-- all metamethods
local meta_all = setmetatable({}, {
  __index = function(t, k) return rawget(t, k) end, __newindex = function(t, k, v) rawset(t, k, v) end,
  __call = function(self, ...) return ... end, __tostring = function() return "meta" end, __name = "MetaAll",
  __len = function() return 0 end, __eq = function() return true end, __lt = function() return false end, __le = function() return true end,
  __concat = function(a, b) return "c" end, __unm = function(a) return a end,
  __add = function() end, __sub = function() end, __mul = function() end, __div = function() end, __mod = function() end,
  __pow = function() end, __idiv = function() end, __band = function() end, __bor = function() end, __bxor = function() end,
  __shl = function() end, __shr = function() end, __bnot = function() end,
  __gc = function() end, __close = function() end, __mode = "kv", __metatable = "locked", __pairs = function(t) return next, t, nil end,
})

-- attribs, goto, labels, empty statements
local const_a <const>, close_b <close> = 1, nil
;;; local semi = 1;
do goto skip; local unreachable = 1; ::skip:: end
for i = 1, 3 do
  for j = 1, 3 do
    if j == 2 then goto continue_inner end
    if i == 2 then goto continue_outer end
    ::continue_inner::
  end
  ::continue_outer::
end
for x = 1.0, 2.0, 0.5 do end
for k, v, c, closing in pairs({}) do break end
while true do if false then break end break end
repeat local scoped = 1 until scoped == 1
if false then elseif false then else end
local function recursive(n) if n <= 0 then return end return recursive(n - 1) end
local function va(...) local a, b = ... return select(2, ...), #{...}, table.pack(...).n end
local f1, f2 = (function() return 1, 2 end)()
local f3 = (function() return 1, 2 end)()
local swap_a, swap_b = 1, 2; swap_a, swap_b = swap_b, swap_a
local tbl_a = { f1, f2, (va(1, 2)) }

-- operator precedence corners
local prec = {
  -2 ^ 2, 2 ^ -2, not nil == true, not (nil == true), 1 .. 2 .. 3, "a" .. "b" == "ab", 1 + 2 << 3 & 4 | 5 ~ 6, #"abc" + 1, -#"abc", - - 1, not not nil,
  1 < 2 == true, 1 ~= 2, a and b or c, nil or false, false and nil, 5 // 2 * 2 % 3, 2^3^2, ~0, ~~0, 7 // 0.0, -7 // 2, 7 % -3, 1 << 63, 1 >> 1, 3 ~ 5,
}

-- standard library tour
local std = {
  string.byte("A"), string.char(72, 105), string.dump(print), string.find("abc", "b", 1, true), string.format("%q %i %c %o %u %X %a %g %5s %-5s %.3s", 1, 2, 65, 8, 9, 255, 1.0, 1.5, "a", "b", "abcdef"),
  string.gmatch("a b", "%a+"), string.gsub("abc", "%w", "%0%0"), string.gsub("abc", "(a)(b)", "%2%1"), string.len("abc"), string.lower("A"), string.match("x=1", "(%w+)=(%d+)"),
  string.pack("<i4 >I2 z s1", 1, 2, "z", "s"), string.packsize("i4"), string.rep("ab", 3, "-"), string.reverse("abc"), string.sub("abc", 2, -1), string.unpack("<i4", "\1\0\0\0"), string.upper("a"),
  ("x"):find("%f[%a]"), ("a.b"):gsub("%.", "%%"), ("  trim  "):match("^%s*(.-)%s*$"), ("a,b"):gmatch("[^,]+"), ("%b()"):len(), ("[%]]"):len(), ("x"):byte(-1),
  table.concat({1, 2}, ","), table.insert({}, 1), table.move({1, 2, 3}, 1, 3, 2), table.pack(1, 2), table.remove({1}), table.sort({3, 1}), table.unpack({1, 2}, 1, 2),
  math.abs(-1), math.ceil(1.5), math.cos(0), math.deg(1), math.exp(1), math.floor(1.5), math.fmod(5, 3), math.huge, math.log(8, 2), math.max(1, 2), math.maxinteger, math.min(1, 2), math.mininteger,
  math.modf(1.5), math.pi, math.rad(180), math.random(), math.random(10), math.random(1, 10), math.randomseed(42), math.sin(0), math.sqrt(4), math.tan(0), math.tointeger(3.0), math.type(1), math.ult(1, 2),
  utf8.char(72, 228, 8364), utf8.charpattern, utf8.codepoint("ä", 1), utf8.len("häh"), utf8.offset("häh", 3), utf8.codes("hä"),
  os.clock(), os.date("*t").year, os.date("!%c"), os.difftime(2, 1), os.getenv("HOME"), os.time{ year = 2026, month = 1, day = 31, hour = 12 }, os.tmpname(),
  io.write("w"), io.read and "r", io.lines and "l", io.open and "o", io.stdout, io.stderr, io.stdin,
  coroutine.close, coroutine.create, coroutine.isyieldable(), coroutine.running(), coroutine.status(coroutine.create(print)), coroutine.wrap, coroutine.yield,
  debug.getinfo(1, "Sl").currentline, debug.traceback("tb", 1), debug.sethook, debug.getlocal(1, 1), debug.gethook(), debug.getmetatable(""),
  load("return 1")(), load(function() return nil end), loadfile, dofile, collectgarbage("count"), collectgarbage("step"), collectgarbage("incremental"), collectgarbage("generational"),
  getmetatable("").__index == string, tostring(1 / 0), tostring(-1 / 0), tostring(0 / 0), tostring(2^63), tostring(1e100), tostring(-0.0), math.tointeger("8"), #arg, ...,
}
local ok_co, co_err = coroutine.close(coroutine.create(function() end))
local cl <close> = setmetatable({}, { __close = function(_, e) print("closed", e) end })
-- ── Lua 5.5: explicit global declarations ──
global counter = 0
global first, second = 1, 2
global <const> LIMIT = 100
global function report(name)
  return "report " .. name
end
do
  global <const> *
end
do
  global *
end

return std, meta_all, obj, prec, tbl_a, numbers_more, escapes_more

