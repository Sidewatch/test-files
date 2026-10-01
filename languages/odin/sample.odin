// Odin dev-2025 (file tags, bit_field, #subtype, #by_ptr, or_else/or_return) — syntax showcase: structs, unions, enums, procedures, generics, defer and context.
/* A block comment
   /* with a nested block */
   still inside */
/// A doc comment.
// TODO: replace the dynamic array with an arena
// FIXME: sorting allocates

#+build !js
#+feature dynamic-literals
#+vet unused, shadowing, using-stmt
#+lazy
#+no-instrumentation
#+private file
package sample

import "core:fmt"
import "core:slice"
import "core:strings"
import "core:mem"
import "core:os"
import rl "vendor:raylib"
import "base:intrinsics"
foreign import libc "system:c"

// ── Constants ──
REORDER_POINT :: 25
GREETING :: "hello"
PI_ISH :: 3.14159
MASK :: 0xFF
FLAGS :: bit_set[Flag; u8]
Name :: distinct string

// ── Literals ──
dec := 1_000_000
hex := 0xFF_EC
oct := 0o755
bin := 0b1010_1010
hexf := 0h3FF0000000000000
flt := 3.14
exp := 1.5e-3
imag := 2i
cplx := 1 + 2i
quat := 1 + 2i + 3j + 4k
yes := true
no := false
nothing := nil
ch := 'a'
ch_esc := '\n'
ch_uni := 'é'
ch_hex := '\x41'
str := "tab:\t newline:\n quote:\" backslash:\\ hex:\x41 uni:é \U0001F4E6 oct:\101"
raw := `raw string with "quotes" and \n kept`
uninit: int = ---
tern := dec > 5 ? "big" : "small"
tern2 := dec if dec > 5 else 0
elvis := maybe_val() or_else 5

// ── Types ──
Flag :: enum u8 { Gift, Rush, Fragile }

Zone :: enum { Cold, Dry = 5, Hazard }

Item :: struct {
    sku:   string `json:"sku"`,
    qty:   int,
    price: f64,
    tags:  [dynamic]string,
    zone:  Zone,
    using pos: Vec2,
}

Vec2 :: struct { x, y: f32 }
Vec3 :: [3]f32
Matrix :: matrix[4, 4]f32

Packed :: struct #packed { a: u8, b: u32 }
Aligned :: struct #align(16) { v: [4]f32 }
Soa :: #soa[4]Vec2

Shape :: union {
    Circle,
    Rect,
    Maybe_Int,
}
Circle :: struct { r: f32 }
Rect :: struct { w, h: f32 }
Maybe_Int :: Maybe(int)

Bit_Fields :: bit_field u16 {
    a: u8 | 4,
    b: u8 | 4,
}

Callback :: proc(x: int) -> int
Handle :: distinct u32
Generic_Pair :: struct($K, $V: typeid) { key: K, value: V }

// ── Procedures ──
low_stock :: proc(items: []Item) -> (low: [dynamic]Item, value: f64) {
    for it in items {
        value += f64(it.qty) * it.price
        if it.qty <= REORDER_POINT do append(&low, it)
    }
    slice.sort_by(low[:], proc(a, b: Item) -> bool { return a.price < b.price })
    return
}

add :: proc(a, b: int) -> int { return a + b }
swap :: proc(a, b: ^$T) { a^, b^ = b^, a^ }
sum :: proc(xs: ..int) -> (total: int) {
    for x in xs { total += x }
    return
}
default_args :: proc(a: int, b := 10, #any_int c: int = 5) -> int { return a + b + c }
named :: proc(first_name: string, last_name: string) {}
contextual :: proc "contextless" () {}
c_call :: proc "c" (x: i32) -> i32 { return x }
@(require_results)
important :: proc() -> int { return 1 }
@(private)
hidden :: proc() {}
@(deferred_out = cleanup)
setup :: proc() -> int { return 0 }
cleanup :: proc(x: int) {}
@(link_name = "puts")
puts :: proc(s: cstring) -> i32 ---
foreign libc { abs :: proc(x: i32) -> i32 --- }

// ── Explicit overloading and generics ──
to_string :: proc{ int_to_string, float_to_string }
int_to_string :: proc(i: int) -> string { return fmt.tprint(i) }
float_to_string :: proc(f: f64) -> string { return fmt.tprint(f) }
max_of :: proc(a, b: $T) -> T where intrinsics.type_is_numeric(T) { return a if a > b else b }

// ── Main ──
main :: proc() {
    items := []Item{{sku = "A-100", qty = 12, price = 4.5}, {sku = "B-200", qty = 40, price = 1.25}, {sku = "C-300", qty = 3, price = 99.0}}
    low, value := low_stock(items)
    defer delete(low)

    for it, i in low {
        fmt.printf("%d. %s: %d left\n", i + 1, it.sku, it.qty)
    }
    fmt.printfln("value: %.2f", value)

    // ── Control flow ──
    if value > 100 {
        fmt.println("rich")
    } else if value > 10 {
        fmt.println("ok")
    } else {
        fmt.println("poor")
    }
    if x, ok := maybe_get(); ok { _ = x }
    for i := 0; i < 3; i += 1 { if i == 1 { continue }; if i == 2 { break } }
    for i in 0..<5 { _ = i }
    for i in 0..=5 { _ = i }
    for i in 10..<0 { _ = i }
    #reverse for i in 0..<3 { _ = i }
    for k, v in map[string]int{"a" = 1} { _, _ = k, v }
    for ch in "héllo" { _ = ch }
    for { break }
    n := 0
    for n < 3 { n += 1 }
    outer: for i in 0..<3 {
        for j in 0..<3 { if i * j > 2 { break outer } }
    }
    switch n {
    case 0: fmt.println("zero")
    case 1, 2: fmt.println("few"); fallthrough
    case 3..=5: fmt.println("some")
    case: fmt.println("other")
    }
    #partial switch z := Zone.Dry; z {
    case .Cold: fmt.println("cold")
    }
    shape: Shape = Circle{r = 1.5}
    switch s in shape {
    case Circle: fmt.println(s.r)
    case Rect: fmt.println(s.w)
    case Maybe_Int: fmt.println("maybe")
    case: fmt.println("nil")
    }
    if c, is_c := shape.(Circle); is_c { _ = c }
    when ODIN_OS == .Windows { fmt.println("windows") } else when ODIN_OS == .Darwin { fmt.println("mac") }

    // ── Operators ──
    a, b := 7, 3
    _ = a + b - a * b / a % b
    _ = a & b | a ~ b &~ b
    _ = a << 2 >> 1
    _ = a == b && a != b || a < b && a >= b
    _ = !true
    _ = -a
    a += 1; a -= 1; a *= 2; a /= 2; a %= 5; a <<= 1; a >>= 1; a &= 3; a |= 4; a ~= 1; a &~= 2
    flags := FLAGS{.Gift, .Rush}
    _ = .Gift in flags
    _ = .Fragile not_in flags
    p := &a
    _ = p^
    ptr: rawptr = p
    _ = cast(^int)ptr
    _ = transmute(u64)f64(1.5)
    _ = auto_cast a
    _ = i32(a)
    _ = (^int)(ptr)
    arr := [?]int{1, 2, 3}
    _ = arr[1:]
    _ = arr[:2]
    _ = len(arr) + cap(arr[:])
    _ = size_of(Item) + align_of(Item) + offset_of(Item, qty)
    _ = typeid_of(int)
    _ = type_info_of(int)
    m := make(map[string]int)
    defer delete(m)
    m["x"] = 1
    v, found := m["x"]
    _, _ = v, found
    s := make([dynamic]int, 0, 8)
    defer delete(s)
    append(&s, 1, 2, 3)
    ordered_remove(&s, 0)
    assert(len(s) == 2, "length")
    ensure(len(s) > 0)
    panic_if := false
    if panic_if { panic("unreachable") }
    unimplemented_ := false
    _ = unimplemented_

    // ── Context, allocators, defer ──
    arena: mem.Arena
    buf: [1024]byte
    mem.arena_init(&arena, buf[:])
    context.allocator = mem.arena_allocator(&arena)
    defer free_all(context.allocator)
    context.logger = {}
    {
        defer fmt.println("block exit")
        defer if n > 0 { fmt.println("conditional defer") }
        fmt.println("in block")
    }
    using fmt
    println("using import")
    #no_bounds_check { _ = arr[0] }
    #assert(size_of(int) >= 4)
    loc := #location()
    _ = loc
    _ = #file
    _ = #line
    _ = #procedure
    _ = #config(DEBUG, false)
    _ = #load("sample.odin", string)
    _ = #sparse [Zone]int{.Cold = 1, .Dry = 2, .Hazard = 3}
    defer_expr := proc() { defer fmt.println("deferred in lambda") }
    defer_expr()
    os.exit(0)
}

maybe_get :: proc() -> (int, bool) { return 1, true }
maybe_val :: proc() -> (int, bool) { return 1, true }
chain :: proc() -> (n: int, ok: bool) {
    n = maybe_val() or_return
    for i in 0..<3 {
        _ = maybe_val() or_continue
        _ = maybe_val() or_break
    }
    return n, true
}
nothing_ptr: ^int

// ── More Odin: directives, attributes and rarely used forms ──
@(init) setup_hook :: proc() {}
@(fini) teardown_hook :: proc() {}
@(thread_local) tls_counter: int
@(rodata) lookup_table := [?]u8{1, 2, 3}
@(export) exported_proc :: proc "c" () {}
@(linkage = "strong") strong_proc :: proc() {}
@(optimization_mode = "favor_size") small_proc :: proc() {}
@(disabled = false) toggled :: proc() {}
@(test) test_something :: proc(t: ^testing.T) { testing.expect(t, true) }
@(cold) rarely_used :: proc() {}
@(builtin) builtin_like :: proc() {}

foreign import lib "system:m"
foreign lib {
    @(link_name = "sin") c_sin :: proc "c" (x: f64) -> f64 ---
    @(default_calling_convention = "c") cos :: proc(x: f64) -> f64 ---
}

Raw_U :: struct #raw_union { i: i32, f: f32 }
Sub :: struct { using base: Vec2, extra: int }
No_Copy :: struct #no_copy { x: int }
Rel :: struct { p: #relative(i16) ^int }
Simd4 :: #simd[4]f32
Dyn :: [dynamic]int
Slc :: []int
Mp :: map[string][dynamic]int
Opt :: Maybe(^int)
Bs :: bit_set[0..<8]
Bs2 :: bit_set[Zone; u32]
Enum_Arr :: [Zone]int
Proc_Group :: proc{ add, sum }
Fn_T :: proc(int, int) -> (int, bool)
Any_T :: any
Cstr :: cstring
Rune_T :: rune

more :: proc() {
    x: int = 5
    y := cast(f32)x
    z := (^u8)(nil)
    w := transmute([4]u8)u32(1)
    pl := &Item{sku = "x"}
    pl.qty = 5
    pl^.qty += 1
    arr := [?]Vec2{{1, 2}, {3, 4}}
    sl := arr[:]
    first, rest := sl[0], sl[1:]
    _, _ = first, rest
    idx := [?]int{0 = 10, 2 = 30, 1 = 20}
    _ = idx
    Num :: enum { A = 1 << 0, B = 1 << 1 }
    nums := bit_set[Num]{.A, .B}
    _ = nums
    #force_inline inlined :: proc() {}
    #force_no_inline not_inlined :: proc() {}
    inlined()
    for i in 0..<3 #no_bounds_check { _ = i }
    switch x {
    case 0..<5: fallthrough
    case 5: break
    }
    s := "text"
    r := []rune("héllo")
    _, _ = s, r
    for c, i in s { _, _ = c, i }
    h := proc(a: int) -> int { return a }
    _ = h(1)
    tup := proc() -> (int, string) { return 1, "a" }
    a1, b1 := tup()
    _, _ = a1, b1
    v := Vec2{1, 2}
    v.x, v.y = v.y, v.x
    v.xy = {3, 4}
    dp: ^^int
    _ = dp
    mat := matrix[2, 2]f32{1, 0, 0, 1}
    _ = mat * mat
    cplx := complex(1, 2)
    _ = real(cplx) + imag(cplx)
    q := quaternion(w = 1, x = 0, y = 0, z = 0)
    _ = q
    ok := true
    ok &&= false
    ok ||= true
    when ODIN_DEBUG { fmt.println("debug") }
    @(static) counter := 0
    counter += 1
    if x := 5; x > 3 { _ = x } else if y := 2; y > 1 { _ = y }
    defer { fmt.println("outer defer") }
    for {
        defer fmt.println("loop defer")
        break
    }
    do_nothing := proc() {}
    do_nothing()
    for x in ([]int{1, 2}) { _ = x }
    v1, v2 := min(1, 2), max(1.0, 2.0)
    _, _ = v1, v2
    raw_data(sl)
    x = abs(-x) + clamp(x, 0, 10)
    #no_type_assert { _ = shape.(Circle) }
    #type proc()
    _ = #exists("file.txt")
    _ = #hash("string", "fnv32a")
    _ = #caller_location
    _ = #caller_expression
    _ = #directive
}

// ── Odin: directives, subtyping, SOA, matrices, enumerated arrays ──
@(deprecated = "use new_api instead")
old_api :: proc() {}
@(warning = "this proc is experimental")
experimental_api :: proc() {}
@(require_results, no_sanitize_address)
checked :: proc() -> int { return 0 }
@(objc_class = "NSObject")
Obj_Class :: struct {}
@(entry_point_only)
entry_only :: proc() {}

Animal :: struct { name: string }
Dog :: struct {
    using animal: Animal `fmt:"-"`,
    #subtype base: Animal,
    tricks: [dynamic]string,
}
Tagged :: struct #min_field_align(4) { a: u8 }
Capped :: struct #max_field_align(2) { a: u32 }
Soa_Pts :: #soa[dynamic]Vec2
Rm :: #row_major matrix[2, 3]f32
Cm :: #column_major matrix[3, 3]f64
Simple_Union :: union #shared_nil { ^int, ^f32 }
No_Nil_Union :: union #no_nil { int, bool }
Sparse_Names := #partial [Zone]string{.Cold = "cold"}
Enum_Backing :: enum u8 { A, B, C }
Dyn_Literal := map[string]int{"a" = 1, "b" = 2}
Bit_Field_Wide :: bit_field u32 {
    flags:  u8   | 8,
    count:  u16  | 12,
    signed: i8   | 4,
    on:     bool | 1,
}

by_ptr_demo :: proc(#by_ptr item: Item) -> int { return item.qty }
c_varargs :: proc "c" (fmt: cstring, #c_vararg args: ..any) -> i32 ---
no_alias :: proc(#no_alias a, b: ^int) {}
any_int :: proc(#any_int n: int) {}
caller :: proc(loc := #caller_location) -> string { return loc.procedure }
tuple_ret :: proc() -> (x, y: int, ok: bool) { return 1, 2, true }
poly_array :: proc(xs: [$N]$T) -> T where N > 0 { return xs[0] }
poly_slice :: proc(xs: []$E, f: proc(E) -> bool) -> int { c := 0; for x in xs { if f(x) { c += 1 } }; return c }
poly_typeid :: proc($T: typeid, n: int) -> []T { return make([]T, n) }
poly_value :: proc($N: int) -> [N]int { return {} }
specialize :: proc(x: $T/[]$E) -> E { return x[0] }
generic_call :: proc() { _ = poly_typeid(int, 3); _ = poly_value(4); _ = specialize([]int{1}) }

control_extras :: proc() {
    #unroll for i in 0..<4 { _ = i }
    #unroll(2) for i in 0..<4 { _ = i }
    x := 1
    y := x if x > 0 else -x
    z := x > 0 ? x : -x
    w := x or_else 5
    _, _, _, _ = y, z, w, x
    if v, ok := tuple_ret_ok(); !ok { return }
    for v in ([?]int{1, 2, 3}) do _ = v
    for v, i in ([?]int{1, 2}) do _, _ = v, i
    if x > 0 do x += 1
    else do x -= 1
    #partial switch Zone.Cold { case .Cold: }
    dw := proc() { for {} }
    _ = dw
    defer if x > 0 do x = 0
    bits := transmute(bit_set[Zone; u8])u8(1)
    _ = bits
    ptr := new(int)
    defer free(ptr)
    ptr^ = 5
    raw := rawptr(ptr)
    _ = raw
    sl := ([^]int)(raw)[:4]
    _ = sl
    mp: [^]int = nil
    _ = mp
    cs := cstring("c")
    gs := string(cs)
    _ = gs
    r1 := 'x'
    r2 := rune(120)
    _, _ = r1, r2
    c1 := cast(u8)r1
    _ = c1
    lim := max(int)
    _ = lim
    a1 := [3]int{1, 2, 3} + [3]int{4, 5, 6}
    _ = a1
    m1 := matrix[2, 2]int{1, 2, 3, 4}
    m2 := transpose(m1)
    _ = m1 * m2
    v2 := Vec2{1, 2} + Vec2{3, 4}
    _ = v2
    swizzle := Vec3{1, 2, 3}.zyx
    _ = swizzle
    cmp := complex128(1 + 2i)
    _ = cmp
}
tuple_ret_ok :: proc() -> (int, bool) { return 0, true }

#assert(size_of(int) == size_of(uintptr))
