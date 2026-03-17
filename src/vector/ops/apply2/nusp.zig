const std = @import("std");

const types = @import("../../../types.zig");

const numeric = @import("../../../numeric.zig");
const vector = @import("../../../vector.zig");

const int = @import("../../../int.zig");

pub fn apply2(allocator: std.mem.Allocator, x: anytype, y: anytype, comptime op: anytype) !vector.Apply2(@TypeOf(x), @TypeOf(y), op) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    comptime var R = types.ReturnTypeFromInputs(op, &.{ X, types.Numeric(Y) });
    const rinfo = @typeInfo(R);
    if (rinfo == .error_union)
        R = rinfo.error_union.payload;

    var result: vector.Sparse(R) = try .init(allocator, y.len, y.nnz);
    errdefer result.deinit(allocator);

    var i: usize = 0;
    while (i < y.nnz) : (i += 1) {
        result.data[i] = if (comptime rinfo != .error_union)
            op(x, y.data[i])
        else
            try op(x, y.data[i]);

        result.idx[i] = y.idx[i];
        result.nnz += 1;
    }

    return result;
}
