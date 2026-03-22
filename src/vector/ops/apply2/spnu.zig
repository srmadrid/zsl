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
    comptime var R = types.ReturnTypeFromInputs(op, &.{ types.Numeric(X), Y });
    const rinfo = @typeInfo(R);
    if (rinfo == .error_union)
        R = rinfo.error_union.payload;

    var result: vector.Sparse(R) = try .init(allocator, x.len, x.nnz);
    errdefer result.deinit(allocator);

    result.nnz = x.nnz;

    var i: usize = 0;
    if (comptime op == numeric.mul or op == numeric.div) {
        const sblr = simd.suggestBaseLength(R);
        const sblx = simd.suggestBaseLength(types.Numeric(X));
        const sbly = simd.suggestBaseLength(Y);

        if (comptime sblr != null and sblx != null and sbly != null) {
            const bl = int.min(sblr.?, int.min(sblx.?, sbly.?));
            const len = result.nnz - (result.nnz % bl);

            while (i < len) : (i += bl) {
                if (comptime op == numeric.mul)
                    simd.mul_(result.data + i, x.data + i, y, bl)
                else
                    simd.div_(result.data + i, x.data + i, y, bl);

                simd.set(result.idx + i, x.idx + i, bl);
            }
        }
    }

    while (i < x.nnz) : (i += 1) {
        result.data[i] = if (comptime rinfo != .error_union)
            op(x.data[i], y)
        else
            try op(x.data[i], y);

        result.idx[i] = x.idx[i];
    }

    return result;
}
