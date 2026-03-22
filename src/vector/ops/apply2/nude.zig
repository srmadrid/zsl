const std = @import("std");

const types = @import("../../../types.zig");

const int = @import("../../../int.zig");

const numeric = @import("../../../numeric.zig");
const vector = @import("../../../vector.zig");

const vecops = @import("../../ops.zig");

const simd = @import("../../../simd.zig");

pub fn apply2(allocator: std.mem.Allocator, x: anytype, y: anytype, comptime op: anytype) !vecops.Apply2(@TypeOf(x), @TypeOf(y), op) {
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
        if (comptime op == numeric.add or op == numeric.sub) {
            const sblr = simd.suggestBaseLength(R);
            const sblx = simd.suggestBaseLength(X);
            const sbly = simd.suggestBaseLength(types.Numeric(Y));

            if (comptime sblr != null and sblx != null and sbly != null) {
                const bl = int.min(sblr.?, int.min(sblx.?, sbly.?));
                const len = result.len - (result.len % bl);

                while (i < len) : (i += bl) {
                    if (comptime op == numeric.add)
                        simd.add_(result.data + i, x, y.data + i, bl)
                    else if (comptime op == numeric.sub)
                        simd.sub_(result.data + i, x, y.data + i, bl);
                }
            }
        }

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
