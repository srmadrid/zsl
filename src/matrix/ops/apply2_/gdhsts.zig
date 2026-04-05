const std = @import("std");

const types = @import("../../../types.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) !void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    if (o.rows != o.cols or y.rows != y.cols or
        o.rows != x.size or o.rows != y.rows)
        return matrix.Error.DimensionMismatch;

    if (comptime types.layoutOf(O) == .col_major) {
        var j: usize = 0;
        while (j < o.cols) : (j += 1) {
            var i: usize = 0;
            while (i < o.rows) : (i += 1) {
                o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
            }
        }
    } else {
        var i: usize = 0;
        while (i < o.rows) : (i += 1) {
            var j: usize = 0;
            while (j < o.cols) : (j += 1) {
                o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
            }
        }
    }

    if (comptime types.layoutOf(X) == .col_major) {
        var j: usize = 0;
        while (j < x.size) : (j += 1) {
            var p: usize = x.ptr[j];
            while (p < x.ptr[j + 1]) : (p += 1) {
                numeric.set(&o.data[o._index(x.idx[p], j)], x.data[p]);

                if (x.idx[p] != j) {
                    numeric.set(&o.data[o._index(j, x.idx[p])], numeric.conj(x.data[p]));
                }
            }
        }
    } else {
        var i: usize = 0;
        while (i < x.size) : (i += 1) {
            var p: usize = x.ptr[i];
            while (p < x.ptr[i + 1]) : (p += 1) {
                numeric.set(&o.data[o._index(i, x.idx[p])], x.data[p]);

                if (i != x.idx[p]) {
                    numeric.set(&o.data[o._index(x.idx[p], i)], numeric.conj(x.data[p]));
                }
            }
        }
    }

    if (comptime types.diagOf(Y) == .unit) {
        var idx: usize = 0;
        while (idx < o.rows) : (idx += 1) {
            op_(&o.data[o._index(idx, idx)], o.data[o._index(idx, idx)], numeric.one(types.Numeric(Y)));
        }
    }

    if (comptime types.layoutOf(Y) == .col_major) {
        var j: usize = 0;
        while (j < y.cols) : (j += 1) {
            var p: usize = y.ptr[j];
            while (p < y.ptr[j + 1]) : (p += 1) {
                op_(&o.data[o._index(y.idx[p], j)], o.data[o._index(y.idx[p], j)], y.data[p]);
            }
        }
    } else {
        var i: usize = 0;
        while (i < y.rows) : (i += 1) {
            var p: usize = y.ptr[i];
            while (p < y.ptr[i + 1]) : (p += 1) {
                op_(&o.data[o._index(i, y.idx[p])], o.data[o._index(i, y.idx[p])], y.data[p]);
            }
        }
    }
}
