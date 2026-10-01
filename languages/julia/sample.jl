#!/usr/bin/env julia
# Julia 1.12 — syntax showcase (julia is not installed here; written against the 1.12 manual)
# ── Comments ──
# Line comment
#=
  Block comment
  #= nested block comment =#
  still inside
=#
# TODO: batch the reorder queries
# FIXME: rounding of fractional units

# ── Modules, imports, exports ──
module Warehouse

using Dates
using Printf: @printf, @sprintf
using LinearAlgebra
import Base: show, +, ==, length, iterate, getindex
import Statistics as Stats
using ..Parent: helper

export Item, Stock, restock!, total_value, @unit, Priced
public internal_helper

# ── Docstrings ──
"""
    Item(sku, quantity, price)

A stock line. Uses `code` and *emphasis*.

# Arguments
- `sku::String`: the identifier
- `quantity::Int`: units on hand

# Examples
```julia
julia> Item("A-100", 5, 2.5)
```
"""
struct Item
    sku::String
    quantity::Int
    price::Float64
end

"Single-line docstring" 
function internal_helper end

# ── Numbers ──
const INT = 42
const NEG = -17
const FLOAT = 3.14159
const FLOAT32 = 2.5f0
const EXP = 6.022e23
const SMALL = 1e-9
const HEX = 0xFF
const HEXFLOAT = 0x1.8p3
const OCT = 0o755
const BIN = 0b1010_0101
const SEP = 1_000_000
const BIG = 123456789012345678901234567890
const BIGFLOAT = big"1.5e100"
const COMPLEX = 3 + 4im
const RATIONAL = 3//4
const SPECIAL = (Inf, -Inf, NaN, Inf32, NaN32, Inf16, π, ℯ, pi, ℯ)
const NOTHING = nothing
const MISSING = missing
const BOOLS = (true, false)

# ── Strings and characters ──
const CHAR = 'a'
const ESC_CHAR = '\n'
const UNI_CHAR = '\u00e9'
const SIMPLE = "Plain with \"quotes\" \t tab \n newline \\ backslash \$ dollar \x41 \u00e9 \U0001F4E6 \101"
const NAME = "Widget"
const INTERP = "Item $NAME has $(length(NAME) * 2) chars and $(NAME[1:2]) and \$escaped"
const TRIPLE = """
    Triple-quoted "string"
      keeps indentation, interpolates $NAME
    """
const RAW = raw"C:\warehouse\bin\$notinterpolated"
const REGEX = r"^[A-Z]{1,3}-(?<num>\d+)$"i
const BYTES = b"\xff\x00bytes"
const VERSION = v"1.10.0"
const CMD = `echo "hello" $NAME`
const UNICODE = "Zürich → 東京 ✓ 📦"
const SYMBOL = :sku
const SYM2 = Symbol("two words")
const QUOTE = :(a + b * 2)
const BLOCKQ = quote
    x = 1
    x + 2
end

# ── Abstract and parametric types ──
abstract type Priced end
abstract type Container{T} <: AbstractVector{T} end
primitive type Octet 8 end

struct Stock{T<:Real} <: Priced
    items::Vector{Item}
    meta::Dict{Symbol,T}
    Stock{T}(items) where {T<:Real} = new{T}(items, Dict{Symbol,T}())
end

mutable struct Counter
    count::Int
    const label::String
    Counter(label) = new(0, label)
end

Base.@kwdef struct Config
    port::Int = 8080
    host::String = "localhost"
    debug::Bool = false
end

const Money = Float64
const Matrix3 = Matrix{Float64}

# ── Functions ──
function total_value(stock::Stock{T})::T where {T<:Real}
    sum(i.quantity * i.price for i in stock.items)
end

restock!(stock, item; kwargs...) = push!(stock.items, item)
square(x) = x^2
add(x::Int, y::Int=1; scale::Float64=1.0, kw...) = (x + y) * scale
variadic(first, rest...) = (first, rest)
(c::Counter)(n) = c.count += n
function (item::Item)(extra)
    item.quantity + extra
end

Base.show(io::IO, item::Item) = print(io, "Item(", item.sku, " ×", item.quantity, ")")
Base.:+(a::Item, b::Item) = Item(a.sku, a.quantity + b.quantity, a.price)
Base.:(==)(a::Item, b::Item) = a.sku == b.sku
Base.length(s::Stock) = length(s.items)
Base.iterate(s::Stock, state=1) = state > length(s) ? nothing : (s.items[state], state + 1)

# ── Closures, anonymous functions ──
double = x -> 2x
adder = (x, y) -> x + y
multi = function (x)
    x + 1
end
compose = double ∘ square
piped = [1, 2, 3] |> sum
broadcasted = double.([1, 2, 3])
mapped = map(x -> x^2, 1:5)
filtered = filter(iseven, 1:10)
folded = foldl(+, 1:10; init=0)

# ── Macros ──
macro unit(n, name)
    quote
        $(esc(n)) * $(string(name))
    end
end

macro checked(ex)
    return :(@assert $(esc(ex)) "check failed: " * $(string(ex)))
end

@generated function gen(x)
    :(x * 2)
end

@inline fast(x) = x + 1
@noinline slow(x) = x - 1
@time sum(1:1000)
@show INT
@assert INT > 0 "must be positive"
@printf("%5.2f|%-8s|%d\n", 3.14159, "ab", 42)
@sprintf("%e", 1234.5)

# ── Operators and expressions ──
a, b = 7, 3
arith = a + b - a * b / 2 ÷ 1 % 5 ^ 2
bitwise = a & b | a ⊻ b << 1 >> 1 >>> 1
cmp = a < b <= a == a != b > a >= b
logic = a > 1 && b < 5 || !(a == b)
div = (a ÷ b, a % b, rem(a, b), mod(a, b), a \ b, a // b)
inplace = [1, 2, 3]
inplace .+= 1
inplace .*= 2
a += 1; a -= 1; a *= 2; a /= 2; a ^= 2; a ÷= 1; a %= 5; a &= 3; a |= 4; a <<= 1; a >>= 1
subset = 1 ∈ [1, 2] && 3 ∉ [1, 2] && [1] ⊆ [1, 2]
ternary = a > b ? "greater" : "not greater"
adjoint = [1 2; 3 4]'
transpose = [1 2; 3 4]'
matrix = [1 2 3; 4 5 6]
vec = [1, 2, 3]
rowvec = [1 2 3]
tuple = (1, "two", 3.0)
named = (sku="A-100", qty=5)
dict = Dict("a" => 1, :b => 2, 3 => "three")
typed = Int[1, 2, 3]
comp = [x^2 for x in 1:10 if x % 2 == 0]
nested_comp = [(i, j) for i in 1:3, j in 1:3]
gen_exp = sum(x^2 for x in 1:10)
dict_comp = Dict(k => v for (k, v) in zip(1:3, "abc"))
range_step = 1:2:10
range_len = range(0, 1; length=5)
slice = vec[2:end]
last_el = vec[end]
begin_el = vec[begin]
splat = max(vec...)
field = named.sku
dotted = Base.Iterators.take(1:10, 3)
isa_check = 1 isa Int
type_assert = (1 + 1)::Int
subtype = Int <: Number
where_ = Vector{T} where T

# ── Control flow ──
function classify(n)
    if n < 0
        "negative"
    elseif n == 0
        "zero"
    else
        "positive"
    end
end

for i in 1:3, j in 1:2
    i == j && continue
    println(i, j)
end

for (idx, val) in enumerate(["a", "b"])
    @printf("%d: %s\n", idx, val)
end

for i ∈ 1:10
    i > 5 && break
end

let x = 1, y = 2
    x + y
end

while a > 0
    a -= 1
end

outer = begin
    t = 1
    t + 1
end

x = if INT > 0 "pos" else "neg" end

# ── Pattern: multiple dispatch ──
describe(x::Int) = "integer"
describe(x::AbstractFloat) = "float"
describe(x::Union{String,Symbol}) = "text"
describe(::Nothing) = "nothing"
describe(x) = "other"

# ── Errors ──
struct StockError <: Exception
    msg::String
end
Base.showerror(io::IO, e::StockError) = print(io, "StockError: ", e.msg)

function risky(n)
    try
        n < 0 && throw(StockError("negative"))
        n == 0 && error("zero")
        n > 100 && throw(ArgumentError("too big"))
        return n
    catch e
        if e isa StockError
            @warn "stock error" e
        else
            rethrow()
        end
    finally
        @info "finished" n
    end
end

# ── Concurrency ──
task = @async begin
    sleep(0.1)
    42
end
fetch(task)
Threads.@threads for i in 1:4
    i^2
end
ch = Channel{Int}(10)
put!(ch, 1)
@sync begin
    @spawn println("spawned")
end

# ── Do-blocks and anonymous ──
open("stock.txt", "w") do io
    write(io, "data")
end
map(1:3) do x
    x * 2
end

# ── Return, global, local, const ──
function scope()
    global counter_total = 0
    local inner = 1
    return inner
end

end # module Warehouse

using .Warehouse
@time Warehouse.total_value(Warehouse.Stock{Float64}([Warehouse.Item("A-100", 5, 2.5)]))

# ── Rare constructs ──
baremodule Bare
using Base
export f
f() = 1
end

module Outer
    module Inner
        const X = 1
    end
    using .Inner: X
    import .Inner
    import ..Main
    import Base: +, -, *, /
    using Base.Iterators: take, drop
    import Base.Threads as BT
    using Printf, Dates, Random
    export @mymacro, MyType; public helper_fn
end

@enum Color red green=2 blue
@enum Fruit::UInt8 begin
    apple
    banana = 10
end

# numbers
numbers_more = (
    1_000.000_1, 0x1p-3, 1f-3, 1.0f0, .5, 5., 1e-3, 1E3, 0xDEAD_BEEF, 0b1_0, 0o7_7,
    1//2, 2im, 3.0im, 1 + 2im, im, Inf16, -0.0, 0x1.8p1, 1_0e1_0, 0x00ff, 0b11111111111111111111111111111111111111,
    typemax(Int), typemin(Int8), 1.0e+3, 12345678901234567890, 0xffffffffffffffffffff,
)

# chars and strings
chars_more = ('\x41', 'é', '\U0001F4E6', '\0', '\'', '\\', '"', '\a', '\b', '\e', '\f', '\r', '\v', '\101', 'λ', '😀')
strings_more = (
    "escapes \a \b \e \f \n \r \t \v \0 \\ \" \$ \x7f é \U0001F4E6 \377",
    "interp $(1 + 1) $name $(name)s $(join(["a", "b"], ", ")) $("nested $("deep")")",
    "line continuation \
     joined",
    """triple "quotes" inside, no escapes needed for ", but \"\"\" works""",
    raw"raw \n $notinterp \"quote",
    raw"""raw triple \ $""",
    r"regex \d+ $"imsx, r"""multi
    line regex"""x,
    b"bytes \xff \x00", b"""triple bytes""",
    v"1.2.3-rc1+build", v"1",
    big"123456789012345678901234567890", big"1.5",
    html"<b>x</b>", md"# markdown $(1 + 1)", ``, `ls -l $(dir)`, ```multi
    line command```,
    Base.Docs.doc"x", String(UInt8[0x41]), :symbol, :+, :(+), :end, Symbol("a b"), QuoteNode(:x), :(:), :[], :a_b!,
)

# operators
ops_more = (
    a .+ b, a .- b, a .* b, a ./ b, a .\ b, a .^ b, a .% b, a .÷ b, a .== b, a .!= b, a .< b, a .<= b, a .> b, a .>= b,
    a .& b, a .| b, a .⊻ b, a .<< b, a .>> b, !a, ~a, -a, +a, √a, ∛a, ∜a, a ∘ b, a × b, a ⋅ b, a ∩ b, a ∪ b, a ∈ b, a ∋ b,
    a ∉ b, a ⊂ b, a ⊃ b, a ⊆ b, a ⊇ b, a ⊊ b, a ≈ b, a ≉ b, a ≠ b, a ≤ b, a ≥ b, a ≡ b, a ≢ b, a === b, a !== b, a ∧ b, a ∨ b,
    a ⊼ b, a ⊽ b, a ↔ b, a → b, a ⇒ b, a ⊕ b, a ⊗ b, a ⊙ b, a ⋆ b, a ∘ b, a \ b, a // b, a ÷ b, a ⊘ b,
    a <: b, a >: b, a isa b, a in b, a ∈ b, a => b, a |> f, f <| a, a:b, a:s:b, (a, b) -> a, x -> -x,
    a ? b : c, a && b || c, a & b | c ⊻ d, a << b >> c >>> d, a^b^c, a' , a'*b, a.', a.:b, A[1, :], A[:, end], A[end÷2], A[begin:end], A[[1, 2], :],
    A[A .> 0], A[CartesianIndex(1, 2)], A[.., 1], @view(A[1, :]), (a, b) = (1, 2), a = b = c, (; x, y) = nt, (a, (b, c)) = (1, (2, 3)),
    a, = [1], a, b... = 1:5, x.y.z, x.:y, Base.:+, Base.:(==), f.(x), f.(x, y), @. a + b * c, a .= b, a .+= b, a ⊻= b, a ÷= b, a \= b, a //= b, a ⊕= b,
)

# types
abstract type Shape{T<:Real} <: Any end
abstract type Numeric <: Number end
primitive type Bits16 <: Integer 16 end
struct Point{T} <: Shape{T}
    x::T
    y::T
end
mutable struct Mut{T<:Number,N}
    const id::Int
    data::NTuple{N,T}
    callback::Union{Nothing,Function}
    Mut{T,N}(id) where {T<:Number,N} = new(id, ntuple(_ -> zero(T), N), nothing)
end
struct Params
    a::Int
    b::Vararg{Int}
end
const IntOrString = Union{Int,String}
const Vec{T} = Vector{T}
const Fn = Function
f_type(::Type{T}) where {T<:Integer} = T
g_type(x::T, y::S) where {T,S<:Real} = x
h_type(::Type{Vector{T}}) where T = T
k_type(::Tuple{Vararg{Int}}) = 0
m_type(x::Union{}) = x
n_type(x::Type{<:Number}) = x
o_type(::Val{N}) where {N} = N
p_type(f::F) where {F<:Function} = f
q_type(x::T where T<:Integer) = x
r_type(::Type{Union{Nothing,T}}) where T = T
s_type(x::AbstractArray{<:Real,2}) = x

# functions and definitions
function multi_dispatch end
function kw_only(; a=1, b::Int=2, kwargs...) a + b end
function pos_and_kw(x, y=2, z...; k=3, l...) x end
function default_depends(a, b=a + 1, c=b * 2) c end
function ret_type(x)::Int x end
function unicode_names(α, β₂, x̂, ẍ, 𝒜) α end
function bang!(a) a end
function (::Type{Point})() Point(0, 0) end
function Base.getindex(p::Point, i::Int) i == 1 ? p.x : p.y end
function Base.setindex!(m::Mut, v, i) m.data = v end
function Base.iterate(p::Point, s=1) s > 2 ? nothing : (p[s], s + 1) end
Base.:*(a::Point, b::Point) = Point(a.x * b.x, a.y * b.y)
Base.:-(a::Point) = Point(-a.x, -a.y)
Base.convert(::Type{Point{T}}, t::Tuple) where T = Point{T}(t...)
Base.promote_rule(::Type{Point{A}}, ::Type{Point{B}}) where {A,B} = Point{promote_type(A, B)}
(f::Point)(t) = f.x * t + f.y
Base.getproperty(p::Point, s::Symbol) = getfield(p, s)
Base.show(io::IO, ::MIME"text/plain", p::Point) = print(io, "Point(", p.x, ", ", p.y, ")")
square_all(xs) = [x^2 for x in xs]
curried(a) = b -> c -> a + b + c
x |> sqrt |> println
1:3 .|> sin
ntuple(i -> i^2, 3)

# macros and meta
macro twice(ex) :($(esc(ex)); $(esc(ex))) end
macro show_expr(ex) quote println($(string(ex)), " = ", $(esc(ex))) end end
@twice println("hi")
@static if Sys.iswindows() 1 else 2 end
@inbounds @simd for i in 1:10 end
@views A[1, :]
@fastmath x * y
@eval f_eval() = 1
@doc "doc via macro" f_doc() = 1
@deprecate old_name new_name
@boundscheck checkbounds(A, 1)
@propagate_inbounds getindex(a, i) = 1
@noinline @inline @generated @nospecialize @specialize
@ccall strlen("hi"::Cstring)::Csize_t
ccall(:clock, Int32, ())
@cfunction(sin, Cdouble, (Cdouble,))
@threadcall(:sleep, Cint, (Cuint,), 1)
@macroexpand @twice x
@which sin(1.0)
@code_warntype f(1)
@time @elapsed @allocated @timed @btime sum(1:10)
@assert true
@info "info" x=1 y=2
@warn "warn"
@error "error" exception=(e, catch_backtrace())
@debug "debug"
@testset "suite" begin
    @test 1 + 1 == 2
    @test_throws ArgumentError error("x")
    @test_broken false
    @test isapprox(1.0, 1.0 + 1e-9; atol=1e-6)
end
@everywhere using Distributed
@distributed (+) for i in 1:10 i end
@sync @async @spawn @spawnat 1 1 + 1
@lock l begin end
@atomic counter += 1
@printf "%d\n" 3
@sprintf "%s" "x"
@kwdef struct KW a::Int = 1 end
@Base.kwdef struct KW2 b = 2 end
@__MODULE__
@__FILE__
@__LINE__
@__DIR__
@__FUNCTION__
@__dot__

expr_forms = (:(x + 1), :($a + $(b + 1)), quote x; y end, :(f(x...)), :($(Expr(:call, :+, 1, 2))), Expr(:block), Meta.parse("1 + 2"),
    :(a = 1), :(function f() end), :(x -> x), :(@m a b), :(a.b), :(a[1]), :(a'), :(a ? b : c), :(::Int), :(<:Number), :($(QuoteNode(:x))), QuoteNode(:y), :(:z))

# control flow
for i in 1:3, j in 1:3 i == j && continue end
for (i, j) in zip(1:3, 4:6) end
for i = 1:3 end
for i ∈ 1:3 end
for outer_i in 1:2
    for j in 1:2
        global gcount += 1
    end
end
let a = 1, b = 2; a + b end
let; end
begin; 1; 2 end
if a elseif b else end
a ? b : c ? d : e
while true break end
try; catch; end
try; error("x"); catch e; showerror(stdout, e); finally; end
try error("e") catch e e finally end
try
    1
catch err
    err isa ErrorException && rethrow()
else
    2
finally
    3
end
function early() return end
function multi_return() return 1, 2 end
function nothing_return() nothing end
x = begin 1 end
y = (1; 2)
z = if a 1 else 2 end
w = for i in 1:3 end
do_block = map(1:3) do i; i end
do_args = foldl(1:3; init=0) do acc, x acc + x end
do_destructure = map(zip(1:3, 4:6)) do (a, b) a + b end
@goto done; @label done
global G1, G2 = 1, 2
local L1
const C1, C2 = 1, 2
const global GC = 1
global const GC2 = 2
export_all = names(Outer; all=true)
isdefined(Main, :x) && eval(:(x = 1))
Base.@locals
Core.eval(Main, :(1 + 1))
include("other.jl"); include_string(Main, "1 + 1")
__precompile__(); using Pkg; Pkg.activate("."); Pkg.add("Example")
atexit(() -> println("bye")); exit(0)

# ── Julia 1.7 – 1.12 additions ──
nt = (x = 1, y = 2)
(; x, y) = nt                       # destructuring by name (1.7)
shorthand = (; x, y)                # named-tuple shorthand
kw_call(; x, y) = x + y
kw_call(; x, y)                     # keyword shorthand at the call site
typed_local::Int = 5                # typed assignment
global typed_global::Float64 = 1.0  # typed global (1.8)
const typed_const::Int = 3          # typed const (1.8)
var"name with spaces" = 1           # non-standard identifiers
var"end" = 2
mem = Memory{Int}(undef, 3)         # Memory type (1.11)
mem[1] = 7
const scoped = Base.ScopedValues.ScopedValue(1)
Base.ScopedValues.@with scoped => 2 begin
    scoped[]
end
@atomic :monotonic atom_counter = 0           # atomic access, ordering as the first argument
Base.@invokelatest sin(1.0)
cond_val = @something nothing 3
fix_two = Base.Fix2(+, 2)
partitioned = Iterators.partition(1:10, 3)
unicode_ids = (αβγ = 1, x₁ = 2, y′ = 3, 𝒵 = 4, ᵢ = 5)
dotted_import = Base.Iterators.Take
first_last = (vec[begin], vec[end], vec[begin+1:end-1])
where_chain(::Type{Vector{T}}) where {T} where {S} = T
macro_in_string = "result: $(@sprintf("%.2f", 3.14159))"
ternary_chain = a < 0 ? "neg" : a == 0 ? "zero" : "pos"
multi_assign = (first, second, rest...) = 1:5
splat_args(args...; kwargs...) = (args, kwargs)
splat_args(vec...; named...)
unpacked = [vec...; vec...]
hcat_vcat = [vec vec; vec vec]
mixed_cat = [1 2; 3 4;;; 5 6; 7 8]            # 3-d literal with ;;;
array_of_arrays = [[1, 2], [3, 4]]
trailing_semicolon = [1, 2, 3];
function (@main)(args)
    println("Hello from @main with ", length(args), " arguments")
    return 0
end
