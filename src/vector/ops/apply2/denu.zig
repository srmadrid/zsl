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
    comptime var R = types.ReturnTypeFromInputs(op, &.{ types.Numeric(X), Y });
    const rinfo = @typeInfo(R);
    if (rinfo == .error_union)
        R = rinfo.error_union.payload;

    var result: vector.Dense(R) = try .init(allocator, x.len);
    errdefer result.deinit(allocator);

    var i: usize = 0;
    if (x.inc == 1) {
        if (comptime op == numeric.add or op == numeric.sub) {
            const sblr = simd.suggestBaseLength(R);
            const sblx = simd.suggestBaseLength(types.Numeric(X));
            const sbly = simd.suggestBaseLength(Y);

            if (comptime sblr != null and sblx != null and sbly != null) {
                const bl = int.min(sblr.?, int.min(sblx.?, sbly.?));
                const len = result.len - (result.len % bl);

                while (i < len) : (i += bl) {
                    if (comptime op == numeric.add)
                        simd.add_(result.data + i, x.data + i, y, bl)
                    else if (comptime op == numeric.sub)
                        simd.sub_(result.data + i, x.data + i, y, bl);
                }
            }
        }

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
