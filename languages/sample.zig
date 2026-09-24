//! Zig: a struct with a method, an error union, and a comptime-sized buffer.
const std = @import("std");

const reorder_point: u32 = 25;

const Item = struct {
    sku: []const u8,
    qty: u32,
    price: f64,

    fn value(self: Item) f64 {
        return @as(f64, @floatFromInt(self.qty)) * self.price;
    }
};

const ParseError = error{ MissingField, BadNumber };

fn parse(line: []const u8) ParseError!Item {
    var it = std.mem.splitScalar(u8, line, ',');
    const sku = it.next() orelse return error.MissingField;
    const qty = std.fmt.parseInt(u32, it.next() orelse return error.MissingField, 10) catch return error.BadNumber;
    const price = std.fmt.parseFloat(f64, it.next() orelse return error.MissingField) catch return error.BadNumber;
    return .{ .sku = sku, .qty = qty, .price = price };
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
}
