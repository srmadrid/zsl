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

    if (x.len != y.len)
        return vector.Error.DimensionMismatch;

    var result: vector.Dense(R) = try .init(allocator, x.len);
    errdefer result.deinit(allocator);

    var i: usize = 0;
    if (x.inc == 1) {
        var iy: usize = 0;
        while (i < result.len) : (i += 1) {
            if (y.idx[iy] == i) {
                result.data[i] = if (comptime rinfo != .error_union)
                    op(x.data[i], y.data[iy])
                else
                    try op(x.data[i], y.data[iy]);

                iy += 1;
            } else {
                result.data[i] = if (comptime rinfo != .error_union)
                    op(x.data[i], numeric.zero(types.Numeric(Y)))
                else
                    try op(x.data[i], numeric.zero(types.Numeric(Y)));
            }
        }
    } else {
        var ix: isize = if (x.inc < 0) (-numeric.cast(isize, x.len) + 1) * x.inc else 0;
        var iy: usize = 0;
        while (i < result.len) : (i += 1) {
            if (y.idx[iy] == i) {
                result.data[i] = if (comptime rinfo != .error_union)
                    op(x.data[numeric.cast(usize, ix)], y.data[iy])
                else
                    try op(x.data[numeric.cast(usize, ix)], y.data[iy]);

                iy += 1;
            } else {
                result.data[i] = if (comptime rinfo != .error_union)
                    op(x.data[numeric.cast(usize, ix)], numeric.zero(types.Numeric(Y)))
                else
                    try op(x.data[numeric.cast(usize, ix)], numeric.zero(types.Numeric(Y)));
            }

            ix += x.inc;
        }
    }

    return result;
}
