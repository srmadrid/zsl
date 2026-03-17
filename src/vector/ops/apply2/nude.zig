const std = @import("std");

const types = @import("../../../types.zig");

const numeric = @import("../../../numeric.zig");
const vector = @import("../../../vector.zig");

pub fn apply2(allocator: std.mem.Allocator, x: anytype, y: anytype, comptime op: anytype) !vector.Apply2(@TypeOf(x), @TypeOf(y), op) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    comptime var R = types.ReturnTypeFromInputs(op, &.{ X, types.Numeric(Y) });
    const rinfo = @typeInfo(R);
    if (rinfo == .error_union)
        R = rinfo.error_union.payload;

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
}
