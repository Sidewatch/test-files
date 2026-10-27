--!strict
-- Luau showcase: every comment, string, number, keyword, type, declaration and operator form.
--[[ A block comment
spanning lines ]]
--[==[ A level-two long comment with ]] inside it ]==]

-- Types
type Point = { x: number, y: number }
export type Shape = "circle" | "square" | { kind: "polygon", sides: number }
type Callback<T...> = (T...) -> ()
type Map<K, V> = { [K]: V }
type Maybe<T> = T?
type Both = Point & { z: number }
type Access = { read name: string, write count: number }
type Fn = (number, string?) -> (boolean, ...any)

-- Locals and literals
local count: number = 0
local name = "Player"
local single = 'it\'s'
local escaped = "tab\tnewline\nquote\"unicode\u{1F600}hex\x41dec\065"
local long = [[a long
string]]
local levelled = [==[with ]] inside]==]
local interpolated = `{name} has {count + 1} points`
local nested = `outer {`inner {count}`} done`
local plainTicks = `no holes here`
local integer, hex, binary, float, exponent = 42, 0xFF, 0b1010, 3.14, 1e-3
local separated, small = 1_000_000, .5
local nothing = nil
local inline = 1 --[[ a long comment can end mid-line ]] + 2
local yes, no = true, false

-- Functions
local function add(a: number, b: number): number
	return a + b
end

local Point = {}

function Point.new(x: number, y: number): Point
	return { x = x, y = y }
end

function Point:length(): number
	return math.sqrt(self.x ^ 2 + self.y ^ 2)
end

local function wrap<T>(value: T): { T }
	return { value }
end

local function total(...: number): number
	local sum = 0
	for _, v in { ... } do
		sum += v
	end
	return sum
end

@native
local function double(n: number): number
	return n * 2
end

-- Control flow
for i = 1, 10, 2 do
	if i % 3 == 0 then
		continue
	elseif i > 7 then
		break
	else
		count -= 1
	end
end

while count < 5 do
	count *= 2
end

repeat
	count /= 2
until count <= 1

for key, value in pairs({ a = 1, b = 2 }) do
	print(key, value)
end

do
	local scoped = 1
	print(scoped)
end

-- Operators
local results = {
	1 + 2 - 3 * 4 / 5 // 6 % 7 ^ 8,
	"a" .. "b",
	#"length",
	not yes and no or yes,
	1 == 1, 1 ~= 2, 1 < 2, 1 <= 2, 2 > 1, 2 >= 1,
	-count,
}
count //= 2
count %= 3
count ^= 2
name ..= "!"

-- If expressions, casts and typeof
local label = if count > 0 then "positive" elseif count < 0 then "negative" else "zero"
local asNumber = (name :: any) :: number
local kind = typeof(name)

-- Roblox services and instances
local Players = game:GetService("Players")
local part = Instance.new("Part")
part.Size = Vector3.new(4, 1, 2)
part.Parent = workspace

Players.PlayerAdded:Connect(function(player: Player)
	print(`{player.Name} joined`)
end)

return {
	add = add,
	wrap = wrap,
	total = total,
	double = double,
	label = label,
	asNumber = asNumber,
	kind = kind,
	results = results,
}
