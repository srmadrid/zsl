const std = @import("std");

const types = @import("../../../types.zig");

const numeric = @import("../../../numeric.zig");
const vector = @import("../../../vector.zig");

const vecops = @import("../../ops.zig");

const int = @import("../../../int.zig");

const simd = @import("../../../simd.zig");

pub fn apply2(allocator: std.mem.Allocator, x: anytype, y: anytype, comptime op: anytype) !vecops.Apply2(@TypeOf(x), @TypeOf(y), op) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    comptime var R = types.ReturnTypeFromInputs(op, &.{ X, types.Numeric(Y) });
    const rinfo = @typeInfo(R);
    if (rinfo == .error_union)
        R = rinfo.error_union.payload;

    var result: vector.Sparse(R) = try .init(allocator, y.len, y.nnz);
    errdefer result.deinit(allocator);

    result.nnz = y.nnz;

    var i: usize = 0;
    if (comptime op == numeric.mul or op == numeric.div) {
        const sblr = simd.suggestBaseLength(R);
        const sblx = simd.suggestBaseLength(X);
        const sbly = simd.suggestBaseLength(types.Numeric(Y));

        if (comptime sblr != null and sblx != null and sbly != null) {
            const bl = int.min(sblr.?, int.min(sblx.?, sbly.?));
            const len = result.nnz - (result.nnz % bl);

            while (i < len) : (i += bl) {
                if (comptime op == numeric.mul)
                    simd.mul_(result.data + i, x, y.data + i, bl)
                else
                    simd.div_(result.data + i, x, y.data + i, bl);

                simd.set(result.idx + i, y.idx + i, bl);
            }
        }
    }

    while (i < y.nnz) : (i += 1) {
        result.data[i] = if (comptime rinfo != .error_union)
            op(x, y.data[i])
        else
            try op(x, y.data[i]);

        result.idx[i] = y.idx[i];
    }

    return result;
}
