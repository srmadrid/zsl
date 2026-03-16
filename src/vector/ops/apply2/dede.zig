const std = @import("std");

const types = @import("../../../types.zig");

const numeric = @import("../../../numeric.zig");
const vector = @import("../../../vector.zig");

pub fn apply2(allocator: std.mem.Allocator, x: anytype, y: anytype, comptime op: anytype) !vector.Apply2(@TypeOf(x), @TypeOf(y), op) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    comptime var R = types.ReturnTypeFromInputs(op, &.{ types.Numeric(X), types.Numeric(Y) });
    const rinfo = @typeInfo(R);
    if (rinfo == .error_union)
        R = rinfo.error_union.payload;

    if (comptime !types.isDenseVector(X)) {
        var result: vector.Dense(R) = try .init(allocator, y.len);
        errdefer result.deinit(allocator);

        var i: usize = 0;
        if (y.inc == 1) {
            while (i < result.len) : (i += 1) {
                result.data[i] = if (comptime rinfo != .error_union)
                    op(x, y.data[i])
                else
                    try op(x, y.data[i]);
            }
        } else {
            var iy: isize = if (y.inc < 0) (-numeric.cast(isize, y.len) + 1) * y.inc else 0;
            while (i < result.len) : (i += 1) {
                result.data[i] = if (comptime rinfo != .error_union)
                    op(x, y.data[numeric.cast(usize, iy)])
                else
                    try op(x, y.data[numeric.cast(usize, iy)]);

                iy += y.inc;
            }
        }

        return result;
    } else if (comptime !types.isDenseVector(Y)) {
        var result: vector.Dense(R) = try .init(allocator, x.len);
        errdefer result.deinit(allocator);

        var i: usize = 0;
        if (x.inc == 1) {
            while (i < result.len) : (i += 1) {
                result.data[i] = if (comptime rinfo != .error_union)
                    op(x.data[i], y)
                else
                    try op(x.data[i], y);
            }
        } else {
            var ix: isize = if (x.inc < 0) (-numeric.cast(isize, x.len) + 1) * x.inc else 0;
            while (i < result.len) : (i += 1) {
                result.data[i] = if (comptime rinfo != .error_union)
                    op(x.data[numeric.cast(usize, ix)], y)
                else
                    try op(x.data[numeric.cast(usize, ix)], y);

                ix += x.inc;
            }
        }

        return result;
    }

    if (x.len != y.len)
        return vector.Error.DimensionMismatch;

    var result: vector.Dense(R) = try .init(allocator, x.len);
    errdefer result.deinit(allocator);

    var i: usize = 0;
    if (x.inc == 1 and y.inc == 1) {
        while (i < result.len) : (i += 1) {
            result.data[i] = if (comptime rinfo != .error_union)
                op(x.data[i], y.data[i])
            else
                try op(x.data[i], y.data[i]);
        }
    } else {
        var ix: isize = if (x.inc < 0) (-numeric.cast(isize, x.len) + 1) * x.inc else 0;
        var iy: isize = if (y.inc < 0) (-numeric.cast(isize, y.len) + 1) * y.inc else 0;
        while (i < result.len) : (i += 1) {
            result.data[i] = if (comptime rinfo != .error_union)
                op(x.data[numeric.cast(usize, ix)], y.data[numeric.cast(usize, iy)])
            else
                try op(x.data[numeric.cast(usize, ix)], y.data[numeric.cast(usize, iy)]);

            ix += x.inc;
            iy += y.inc;
        }
    }

    return result;
}
