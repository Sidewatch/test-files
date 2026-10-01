//! Module-level doc comment (//!): the warehouse stock library.
//! TODO: persist to disk. FIXME: overflow on bulk restock.

// ── Comments ───────────────────────────────────────────────
// Plain line comment. Zig has no block comments.
/// Doc comment attached to the declaration below.
/// Supports multiple lines.

// ── Imports and builtin constants ──────────────────────────
const std = @import("std");
const builtin = @import("builtin");
const math = std.math;
const mem = std.mem;
const testing = std.testing;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

// ── Constants and numbers ──────────────────────────────────
const reorder_point: u32 = 25;
const app_name = "Warehouse";
const ratio: f64 = 0.75;
const decimal = 1_000_000;
const hex = 0xFF_FF;
const octal = 0o755;
const binary = 0b1010_1010;
const float = 3.14159;
const exponent = 1.5e-3;
const hex_float = 0x1.8p3;
const big: u128 = 340282366920938463463374607431768211455;
const char_lit = 'a';
const unicode_char = '\u{1F4E6}';
const escape_char = '\n';
const hex_escape = '\x41';
const maybe_true = true;
const maybe_false = false;
const nothing = null;
const undef: u32 = undefined;
const inf = math.inf(f64);
const nan = math.nan(f64);

// ── Strings ────────────────────────────────────────────────
const plain = "double \"quoted\" with \t tab, \n newline, \\ backslash, \x41, \u{263A}";
const multiline =
    \\Multiline string literal.
    \\Each line starts with two backslashes.
    \\  Escapes like \n are NOT processed here, and "quotes" are fine.
;
const bytes = [_]u8{ 0x01, 0x02, 'a', 255 };
const at_name = @"quoted identifier with spaces";
const @"error" = 1;

// ── Types: structs, enums, unions, errors ──────────────────
const Status = enum(u8) {
    pending,
    paid = 5,
    cancelled,

    pub fn label(self: Status) []const u8 {
        return switch (self) {
            .pending => "pending",
            .paid => "paid",
            .cancelled => "cancelled",
        };
    }
};

const Perm = packed struct(u8) {
    read: bool = false,
    write: bool = false,
    exec: bool = false,
    _padding: u5 = 0,
};

const Item = struct {
    sku: []const u8,
    qty: u32,
    price: f64,
    status: Status = .pending,
    tags: ?[]const []const u8 = null,

    const Self = @This();
    pub const default_qty = 0;

    pub fn init(sku: []const u8, qty: u32, price: f64) Self {
        return .{ .sku = sku, .qty = qty, .price = price };
    }

    pub fn value(self: Item) f64 {
        return @as(f64, @floatFromInt(self.qty)) * self.price;
    }

    pub fn restock(self: *Self, amount: u32) void {
        self.qty += amount;
    }
};

const Outcome = union(enum) {
    item: Item,
    message: []const u8,
    code: i32,
    none,
};

const Number = extern union {
    int: i32,
    float: f32,
};

const ParseError = error{ MissingField, BadNumber, Overflow };
const AllErrors = ParseError || error{OutOfMemory};
const Handle = *anyopaque;
const Callback = *const fn (u32) callconv(.C) u32;
const Matrix = [3][3]f32;

// ── Generics and comptime ──────────────────────────────────
fn Stack(comptime T: type) type {
    return struct {
        items: ArrayList(T),

        const Self = @This();

        pub fn init(allocator: Allocator) Self {
            return .{ .items = ArrayList(T).init(allocator) };
        }

        pub fn deinit(self: *Self) void {
            self.items.deinit();
        }

        pub fn push(self: *Self, value: T) !void {
            try self.items.append(value);
        }

        pub fn pop(self: *Self) ?T {
            return self.items.popOrNull();
        }
    };
}

fn max(comptime T: type, a: T, b: T) T {
    return if (a > b) a else b;
}

fn fib(comptime n: u32) u32 {
    return if (n < 2) n else fib(n - 1) + fib(n - 2);
}

const table = blk: {
    var result: [8]u32 = undefined;
    for (&result, 0..) |*slot, i| {
        slot.* = @intCast(i * i);
    }
    break :blk result;
};

comptime {
    std.debug.assert(fib(10) == 55);
}

// ── Functions ──────────────────────────────────────────────
fn parse(line: []const u8) ParseError!Item {
    var it = std.mem.splitScalar(u8, line, ',');
    const sku = it.next() orelse return error.MissingField;
    const qty = std.fmt.parseInt(u32, it.next() orelse return error.MissingField, 10) catch return error.BadNumber;
    const price = std.fmt.parseFloat(f64, it.next() orelse return error.MissingField) catch return error.BadNumber;
    return .{ .sku = sku, .qty = qty, .price = price };
}

fn add(a: i32, b: i32) callconv(.Inline) i32 {
    return a + b;
}

export fn exported(x: u32) u32 {
    return x * 2;
}

extern "c" fn puts(s: [*:0]const u8) c_int;

inline fn square(x: u32) u32 {
    return x * x;
}

noinline fn unlikely() void {
    @setCold(true);
}

fn variadic(args: anytype) void {
    inline for (std.meta.fields(@TypeOf(args))) |field| {
        std.debug.print("{s}\n", .{field.name});
    }
}

// ── Pointers, slices, optionals ────────────────────────────
fn pointers() void {
    var x: u32 = 10;
    const ptr: *u32 = &x;
    const const_ptr: *const u32 = &x;
    const many: [*]u32 = @ptrCast(ptr);
    const sentinel: [*:0]const u8 = "hello";
    const slice: []const u8 = "hello"[1..3];
    const arr = [_]u32{ 1, 2, 3, 4 };
    const sub = arr[1..];
    const opt: ?u32 = null;
    const unwrapped = opt orelse 0;
    const forced = opt.?;
    ptr.* += 1;
    _ = .{ const_ptr, many, sentinel, slice, sub, unwrapped, forced };
    if (opt) |v| {
        _ = v;
    } else {
        _ = 0;
    }
    const aligned: *align(4) u32 = @alignCast(ptr);
    const volatile_ptr: *volatile u32 = ptr;
    _ = .{ aligned, volatile_ptr };
}

// ── Operators ──────────────────────────────────────────────
fn operators(a: i32, b: i32) i32 {
    var r = a + b - a * b / 2 % 7;
    r += 1;
    r -= 1;
    r *= 2;
    r /= 2;
    r %= 5;
    r <<= 1;
    r >>= 1;
    r &= 0xF;
    r |= 1;
    r ^= 2;
    r +%= 1;
    r -%= 1;
    r *%= 2;
    r +|= 1;
    r -|= 1;
    const wrap = a +% b;
    const sat = a +| b;
    const bits = ~a & b | a ^ b << 1 >> 1;
    const logic = !(a > b) and (a < b) or (a >= b) or (a <= b) or (a == b) or (a != b);
    const concat_arr = "ab" ++ "cd";
    const repeated = "ab" ** 3;
    const tern = if (logic) wrap else sat;
    _ = .{ bits, concat_arr, repeated };
    return tern;
}

// ── Control flow ───────────────────────────────────────────
pub fn flow(n: u32) !u32 {
    var total: u32 = 0;
    var i: u32 = 0;
    while (i < n) : (i += 1) {
        if (i == 3) continue;
        if (i == 8) break;
        total += i;
    }
    for (0..n) |k| total += @intCast(k);
    for ([_]u32{ 1, 2, 3 }, 0..) |value, index| {
        total += value + @as(u32, @intCast(index));
    }
    outer: for (0..3) |x| {
        for (0..3) |y| {
            if (x * y == 4) break :outer;
            if (y == 1) continue :outer;
        }
    }
    const label_value = blk: {
        if (total > 10) break :blk 1;
        break :blk 2;
    };
    switch (n) {
        0 => total = 0,
        1, 2 => total = 1,
        3...9 => total = 2,
        else => {},
    }
    const s = switch (label_value) {
        1 => "one",
        2 => "two",
        else => unreachable,
    };
    _ = s;
    while (nextOpt()) |value| {
        total += value;
    } else {
        total += 1;
    }
    defer total = 0;
    errdefer std.debug.print("failed\n", .{});
    return total;
}

fn nextOpt() ?u32 {
    return null;
}

// ── Error handling ─────────────────────────────────────────
fn mayFail(x: i32) !i32 {
    if (x < 0) return error.Negative;
    return x;
}

fn handle() void {
    const v = mayFail(1) catch |err| {
        std.debug.print("error: {s}\n", .{@errorName(err)});
        return;
    };
    const w = mayFail(2) catch 0;
    const u = try mayFail(3);
    _ = .{ v, w, u };
    if (mayFail(4)) |ok| {
        _ = ok;
    } else |err| {
        _ = err;
    }
}

// ── Async-free concurrency, builtins, assembly ─────────────
fn builtins() void {
    const a: u8 = @intCast(300 & 0xFF);
    const b = @as(f32, @floatFromInt(a));
    const c = @sizeOf(Item) + @alignOf(Item) + @bitSizeOf(u7) + @offsetOf(Item, "qty");
    const d = @TypeOf(a, b);
    const e = @typeName(d);
    const f = @tagName(Status.paid);
    const g = @intFromEnum(Status.paid);
    const h = @enumFromInt(1);
    const i = @min(1, 2) + @max(3, 4) + @abs(-5) + @mod(7, 3) + @rem(7, 3);
    const j = @sqrt(2.0) + @sin(1.0) + @floor(2.5) + @ceil(2.5) + @round(2.5);
    const k = @addWithOverflow(@as(u8, 255), 1);
    const l = @bitCast(@as(u32, 1));
    const m = @truncate(@as(u32, 0x1234));
    const n = @shlExact(@as(u8, 1), 2);
    const o = @embedFile("data.txt");
    const p = @src().line;
    const q = @import("std");
    @compileLog("compile-time log");
    @compileError("unreachable in practice");
    _ = .{ b, c, e, f, g, h, i, j, k, l, m, n, o, p, q };
}

fn assembly() void {
    asm volatile ("nop");
}

threadlocal var counter: u32 = 0;
var global_state: u32 linksection(".data") = 0;
const aligned_global: u32 align(16) = 0;
pub const Config = struct { verbose: bool = false };
usingnamespace @import("helpers.zig");

// ── Tests ──────────────────────────────────────────────────
test "item value" {
    const item = Item.init("WGT-100", 12, 4.5);
    try testing.expectEqual(@as(f64, 54.0), item.value());
    try testing.expect(item.qty <= reorder_point);
    try testing.expectError(error.MissingField, parse("bad"));
}

test {
    _ = Stack(u32);
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const lines = [_][]const u8{ "A-100,12,4.5", "B-200,40,1.25", "bad" };
    var total: f64 = 0;
    for (lines) |line| {
        const item = parse(line) catch |err| {
            try stdout.print("skip {s}: {s}\n", .{ line, @errorName(err) });
            continue;
        };
        total += item.value();
        if (item.qty <= reorder_point) try stdout.print("reorder {s}\n", .{item.sku});
    }
    try stdout.print("value: {d:.2}\n", .{total});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var stack = Stack(u32).init(gpa.allocator());
    defer stack.deinit();
    try stack.push(1);
    suspend {}
    resume @frame();
    await async flow(1);
    nosuspend _ = stack.pop();
}

// ── More type forms ────────────────────────────────────────
const Opaque = opaque {
    pub fn describe(self: *Opaque) void {
        _ = self;
    }
};

const PackedUnion = packed union {
    int: u32,
    bytes: [4]u8,
};

const ExternStruct = extern struct {
    a: c_int,
    b: c_long,
    c: [*c]u8,
};

const Tagged = union(Status) {
    pending: void,
    paid: u32,
    cancelled: []const u8,
};

const AutoEnum = enum { a, b, c, _ };
const ExplicitTag = enum(u2) { x = 1, y = 2, z = 3 };
const Vec4 = @Vector(4, f32);
const Frame = anyframe;
const FrameOf = anyframe->u32;
const Many = [*]const u8;
const Sentinel = [:0]const u8;
const ManySentinel = [*:0]u8;
const CPtr = [*c]const u8;
const AlignedPtr = *align(8) const volatile u32;
const AllowZero = *allowzero u32;
const AddrSpacePtr = *addrspace(.generic) u32;
const ErrorSet = error{ A, B } || error{C};
const MaybeErr = ?anyerror!u32;
const FnType = fn (a: u32, comptime T: type, noalias p: *u8, ...) callconv(.C) void;
const BigInt = u1;
const OddInt: type = i7;
const ArbitraryFloat = f80;
const CTypes = struct { a: c_short, b: c_ushort, c: c_int, d: c_uint, e: c_long, f: c_ulong, g: c_longlong, h: c_ulonglong, i: c_longdouble };
const Special = struct { a: void, b: noreturn, c: type, d: anytype_placeholder, e: comptime_int, f: comptime_float, g: @TypeOf(null), h: @TypeOf(undefined) };
const anytype_placeholder = u8;

// ── Switch forms and labelled blocks ───────────────────────
fn switches(t: Tagged, e: AutoEnum, n: u32) u32 {
    const a = switch (t) {
        .pending => 0,
        .paid => |amount| amount,
        .cancelled => |reason| @intCast(reason.len),
    };
    const b = switch (e) {
        .a, .b => 1,
        .c => 2,
        _ => 3,
    };
    const c = switch (n) {
        0...9 => 1,
        10, 20, 30 => 2,
        else => |v| v,
    };
    const d = switch (t) {
        inline .paid, .pending => |payload, tag| blk: {
            _ = payload;
            _ = tag;
            break :blk 5;
        },
        else => 6,
    };
    sw: switch (n) {
        0 => continue :sw 1,
        1 => break :sw,
        else => {},
    }
    return a + b + c + d;
}

fn comptimeStuff(comptime n: usize, args: anytype) [n]u8 {
    comptime var i = 0;
    var out: [n]u8 = undefined;
    inline while (i < n) : (i += 1) {
        out[i] = @intCast(i);
    }
    inline for (args) |arg| {
        _ = arg;
    }
    comptime {
        if (n == 0) @compileError("n must be positive");
    }
    return out;
}

fn errorsAndOptionals(maybe: ?u32, result: anyerror!u32) !void {
    const a = maybe orelse unreachable;
    const b = result catch unreachable;
    const c = maybe.?;
    const d = result catch |err| switch (err) {
        error.OutOfMemory => return err,
        else => 0,
    };
    if (maybe) |*ptr| ptr.* += 1;
    while (maybe) |value| : (_ = value) break;
    for ([_]u8{ 1, 2 }, "ab") |x, y| _ = .{ x, y };
    errdefer |err| std.debug.print("{s}\n", .{@errorName(err)});
    _ = .{ a, b, c, d };
    return error.Unexpected;
}

fn pointerForms(p: *u32, s: []u8, m: [*]u8) void {
    const slice = m[0..4];
    const sentinel_slice = m[0..4 :0];
    const arr_ptr: *[4]u8 = slice[0..4];
    const len = s.len + s.ptr[0];
    const int_from_ptr = @intFromPtr(p);
    const ptr_from_int: *u32 = @ptrFromInt(0x1000);
    const casted = @as(*const u8, @ptrCast(p));
    const aligned: *align(1) u32 = @alignCast(@ptrCast(p));
    const field_ptr = &ExternStruct{ .a = 1, .b = 2, .c = undefined }.a;
    p.* = 5;
    _ = .{ sentinel_slice, arr_ptr, len, int_from_ptr, ptr_from_int, casted, aligned, field_ptr };
}

fn literals() void {
    const enum_lit: AutoEnum = .a;
    const anon_struct = .{ .x = 1, .y = 2 };
    const tuple = .{ 1, "two", 3.0 };
    const nested = .{ .list = [_]u8{ 1, 2 }, .inner = .{ .z = true } };
    const array_2d = [2][2]u8{ .{ 1, 2 }, .{ 3, 4 } };
    const repeat = [_]u8{0} ** 8;
    const str_concat = "a" ++ "b";
    const vec: Vec4 = .{ 1, 2, 3, 4 };
    const splat: Vec4 = @splat(1.5);
    const labeled = blk: {
        break :blk 42;
    };
    _ = .{ enum_lit, anon_struct, tuple, nested, array_2d, repeat, str_concat, vec, splat, labeled };
}

pub usingnamespace struct {
    pub const exported_decl = 1;
};

pub export fn c_entry() callconv(.C) void {}

pub extern "kernel32" fn GetTickCount() callconv(.winapi) u32;

test "switch forms" {
    try testing.expectEqual(@as(u32, 5), switches(.{ .paid = 5 }, .a, 0) - 1 - 1 - 1 + 3 - 3 + 5 - 5 + 0 + 0 + 0);
}

test "error handling" {
    try testing.expectError(error.Unexpected, errorsAndOptionals(1, 2));
}
