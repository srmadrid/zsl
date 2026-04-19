const std = @import("std");

const meta = @import("../../../meta.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = meta.Child(@TypeOf(o));
    const X: type = @TypeOf(x);

    if (comptime meta.layoutOf(O) == .col_major) {
        var j: usize = 0;
        while (j < o.cols) : (j += 1) {
            if (comptime meta.uploOf(O) == .upper) {
                var i: usize = 0;
                while (i <= j) : (i += 1) {
                    o.data[o._index(i, j)] = numeric.zero(meta.Numeric(O));
                }
            } else {
                var i: usize = j;
                while (i < o.rows) : (i += 1) {
                    o.data[o._index(i, j)] = numeric.zero(meta.Numeric(O));
                }
            }
        }
    } else {
        var i: usize = 0;
        while (i < o.rows) : (i += 1) {
            if (comptime meta.uploOf(O) == .lower) {
                var j: usize = 0;
                while (j <= i) : (j += 1) {
                    o.data[o._index(i, j)] = numeric.zero(meta.Numeric(O));
                }
            } else {
                var j: usize = i;
                while (j < o.cols) : (j += 1) {
                    o.data[o._index(i, j)] = numeric.zero(meta.Numeric(O));
                }
            }
        }
    }

    if (comptime meta.layoutOf(X) == .col_major) {
        var j: usize = 0;
        while (j < x.cols) : (j += 1) {
            var p: usize = x.ptr[j];
            while (p < x.ptr[j + 1]) : (p += 1) {
                if (comptime meta.uploOf(O) == meta.uploOf(X))
                    op_(&o.data[o._index(x.idx[p], j)], x.data[p], y)
                else
                    op_(&o.data[o._index(j, x.idx[p])], numeric.conj(x.data[p]), y);
            }
        }
    } else {
        var i: usize = 0;
        while (i < x.rows) : (i += 1) {
            var p: usize = x.ptr[i];
            while (p < x.ptr[i + 1]) : (p += 1) {
                if (comptime meta.uploOf(O) == meta.uploOf(X))
                    op_(&o.data[o._index(i, x.idx[p])], x.data[p], y)
                else
                    op_(&o.data[o._index(x.idx[p], i)], numeric.conj(x.data[p]), y);
            }
        }
    }
}
