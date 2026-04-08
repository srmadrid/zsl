const std = @import("std");

const zsl = @import("zsl");

pub fn printVector(desc: []const u8, v: anytype) void {
    std.debug.print("\nVector {s}:\n", .{desc});

    var i: usize = 0;
    while (i < v.len) : (i += 1) {
        if (comptime zsl.types.isComplex(zsl.types.Numeric(@TypeOf(v)))) {
            std.debug.print("{d} + {d}i\n", .{ (v.get(i) catch unreachable).re, (v.get(i) catch unreachable).im });
        } else {
            std.debug.print("{d}\n", .{v.get(i) catch unreachable});
        }
    }
    std.debug.print("\n", .{});
}

pub fn randomVector(comptime V: type, allocator: std.mem.Allocator, rand: std.Random, len: usize, nnz: usize) !V {
    switch (comptime zsl.types.vectorType(V)) {
        .dense => {
            var result: V = try .init(allocator, len);

            var i: usize = 0;
            while (i < len) : (i += 1) {
                result.set(
                    i,
                    zsl.numeric.cast(
                        zsl.types.Numeric(V),
                        if (comptime zsl.types.isComplex(zsl.types.Numeric(V)))
                            zsl.cf64{ .re = rand.float(f64), .im = rand.float(f64) }
                        else
                            rand.float(f64),
                    ),
                ) catch unreachable;
            }

            return result;
        },
        .sparse => {
            var result: V = try .init(allocator, len, nnz);
            errdefer result.deinit(allocator);

            // generate random indices
            var count: usize = 0;
            while (count < nnz) : (count += 1) {
                const i = rand.intRangeAtMost(usize, 0, len - 1);
                try result.set(
                    allocator,
                    i,
                    zsl.numeric.cast(
                        zsl.types.Numeric(V),
                        if (comptime zsl.types.isComplex(zsl.types.Numeric(V)))
                            zsl.cf64{ .re = rand.float(f64), .im = rand.float(f64) }
                        else
                            rand.float(f64),
                    ),
                );
            }

            return result;
        },
        else => unreachable,
    }
}

pub fn correctApply2(comptime O: type, allocator: std.mem.Allocator, len: usize, u: anytype, v: anytype, op_: anytype) !zsl.vector.Dense(O) {
    const result: zsl.vector.Dense(O) = try .init(allocator, len);

    var i: usize = 0;
    while (i < result.len) : (i += 1) {
        op_(
            &result.data[result._index(i)],
            if (comptime zsl.types.isVector(@TypeOf(u))) u.get(i) catch unreachable else u,
            if (comptime zsl.types.isVector(@TypeOf(v))) v.get(i) catch unreachable else v,
        );
    }

    return result;
}

pub fn areEql(u: anytype, v: anytype) !void {
    var all_eql = true;

    var i: usize = 0;
    while (i < v.len) : (i += 1) {
        all_eql = all_eql and zsl.numeric.eq(u.get(i) catch unreachable, v.get(i) catch unreachable);
    }

    if (!all_eql)
        return error.NotEqual;
}

test {
    _ = @import("vector/apply2.zig");
    _ = @import("vector/apply2_.zig");
}
