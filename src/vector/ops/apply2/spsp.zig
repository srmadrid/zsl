const std = @import("std");

const types = @import("../../../types.zig");

const numeric = @import("../../../numeric.zig");
const vector = @import("../../../vector.zig");

const int = @import("../../../int.zig");

pub fn apply2(allocator: std.mem.Allocator, x: anytype, y: anytype, comptime op: anytype) !vector.Apply2(@TypeOf(x), @TypeOf(y), op) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    comptime var R = types.ReturnTypeFromInputs(op, &.{ types.Numeric(X), types.Numeric(Y) });
    const rinfo = @typeInfo(R);
    if (rinfo == .error_union)
        R = rinfo.error_union.payload;

    if (x.len != y.len)
        return vector.Error.DimensionMismatch;

    var result: vector.Sparse(R) = try .init(allocator, x.len, int.min(x.nnz + y.nnz, x.len));
    errdefer result.deinit(allocator);

    var ix: usize = 0;
    var iy: usize = 0;
    while (ix < x.nnz and iy < y.nnz) {
        if (x.idx[ix] == y.idx[iy]) {
            result.data[result.nnz] = if (comptime rinfo != .error_union)
                op(x.data[ix], y.data[iy])
            else
                try op(x.data[ix], y.data[iy]);

            result.idx[result.nnz] = x.idx[ix];
            result.nnz += 1;
            ix += 1;
            iy += 1;
        } else if (x.idx[ix] < y.idx[iy]) {
            result.data[result.nnz] = if (comptime rinfo != .error_union)
                op(x.data[ix], numeric.zero(types.Numeric(Y)))
            else
                try op(x.data[ix], numeric.zero(types.Numeric(Y)));

            result.idx[result.nnz] = x.idx[ix];
            result.nnz += 1;
            ix += 1;
        } else {
            result.data[result.nnz] = if (comptime rinfo != .error_union)
                op(numeric.zero(types.Numeric(X)), y.data[iy])
            else
                try op(numeric.zero(types.Numeric(X)), y.data[iy]);

            result.idx[result.nnz] = y.idx[iy];
            result.nnz += 1;
            iy += 1;
        }
    }

    while (ix < x.nnz) : (ix += 1) {
        result.data[result.nnz] = if (comptime rinfo != .error_union)
            op(x.data[ix], numeric.zero(types.Numeric(Y)))
        else
            try op(x.data[ix], numeric.zero(types.Numeric(Y)));

        result.idx[result.nnz] = x.idx[ix];
        result.nnz += 1;
    }

    while (iy < y.nnz) : (iy += 1) {
        result.data[result.nnz] = if (comptime rinfo != .error_union)
            op(numeric.zero(types.Numeric(X)), y.data[iy])
        else
            try op(numeric.zero(types.Numeric(X)), y.data[iy]);

        result.idx[result.nnz] = y.idx[iy];
        result.nnz += 1;
    }

    return result;
}
