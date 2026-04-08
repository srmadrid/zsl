const std = @import("std");

const types = @import("../../../types.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));
    const Y: type = @TypeOf(y);

    if (comptime types.layoutOf(O) == .col_major) {
        var j: usize = 0;
        while (j < o.cols) : (j += 1) {
            if (comptime types.uploOf(O) == .upper) {
                var i: usize = 0;
                while (i <= j) : (i += 1) {
                    o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                }
            } else {
                var i: usize = j;
                while (i < o.rows) : (i += 1) {
                    o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                }
            }
        }
    } else {
        var i: usize = 0;
        while (i < o.rows) : (i += 1) {
            if (comptime types.uploOf(O) == .lower) {
                var j: usize = 0;
                while (j <= i) : (j += 1) {
                    o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                }
            } else {
                var j: usize = i;
                while (j < o.cols) : (j += 1) {
                    o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                }
            }
        }
    }

    if (comptime types.layoutOf(Y) == .col_major) {
        var j: usize = 0;
        while (j < y.rows) : (j += 1) {
            var p: usize = y.ptr[j];
            while (p < y.ptr[j + 1]) : (p += 1) {
                if (comptime types.uploOf(O) == types.uploOf(Y))
                    op_(&o.data[o._index(y.idx[p], j)], x, y.data[p])
                else
                    op_(&o.data[o._index(j, y.idx[p])], x, numeric.conj(y.data[p]));
            }
        }
    } else {
        var i: usize = 0;
        while (i < y.cols) : (i += 1) {
            var p: usize = y.ptr[i];
            while (p < y.ptr[i + 1]) : (p += 1) {
                if (comptime types.uploOf(O) == types.uploOf(Y))
                    op_(&o.data[o._index(i, y.idx[p])], x, y.data[p])
                else
                    op_(&o.data[o._index(y.idx[p], i)], x, numeric.conj(y.data[p]));
            }
        }
    }
}
