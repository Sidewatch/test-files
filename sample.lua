-- Vector2 module: simple 2D vector math
local Vector2 = {}
Vector2.__index = Vector2

-- Mathematical constants
local MAX_MAGNITUDE = 1000
local PI = 3.14159

-- Constructor for a new Vector2 instance
function Vector2.new(x, y)
    local self = setmetatable({}, Vector2)
    self.x = x or 0
    self.y = y or 0
    return self
end

-- Method: compute the magnitude of the vector
function Vector2:magnitude()
    local squared = self.x * self.x + self.y * self.y
    return math.sqrt(squared)
end

-- Method: normalize the vector in place
function Vector2:normalize()
    local mag = self:magnitude()
    if mag > 0 then
        self.x = self.x / mag
        self.y = self.y / mag
    end
    return self
end

local function describe(vec)
    local label = "Vector2(" .. tostring(vec.x) .. ", " .. tostring(vec.y) .. ")"
    print(label)
    return label
end

-- Create a couple of vectors and use them
local a = Vector2.new(3, 4)
local b = Vector2.new(6, 8)

print("Magnitude of a:", a:magnitude())
describe(b:normalize())

return Vector2
