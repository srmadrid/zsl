const std = @import("std");

const types = @import("../../../types.zig");

const numeric = @import("../../../numeric.zig");
const vector = @import("../../../vector.zig");

pub fn apply2(allocator: std.mem.Allocator, x: anytype, y: anytype, comptime op: anytype) !vector.Apply2(@TypeOf(x), @TypeOf(y), op) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    comptime var R = types.ReturnTypeFromInputs(op, &.{ types.Numeric(X), Y });
    const rinfo = @typeInfo(R);
    if (rinfo == .error_union)
        R = rinfo.error_union.payload;

    var result: vector.Sparse(R) = try .init(allocator, x.len, x.nnz);
    errdefer result.deinit(allocator);

    var i: usize = 0;
    while (i < x.nnz) : (i += 1) {
        result.data[i] = if (comptime rinfo != .error_union)
            op(x.data[i], y)
        else
            try op(x.data[i], y);

        result.idx[i] = x.idx[i];
        result.nnz += 1;
    }

    return result;
}
