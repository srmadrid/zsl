const std = @import("std");

const meta = @import("../../../meta.zig");
const int = @import("../../../int.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = meta.Child(@TypeOf(o));
    const X: type = @TypeOf(x);

    if (comptime meta.layoutOf(O) == .col_major) {
        var j: usize = 0;
        while (j < o.cols) : (j += 1) {
            var i: usize = 0;
            while (i < int.min(j, o.rows)) : (i += 1) {
                o.data[o._index(i, j)] = numeric.zero(meta.Numeric(O));
            }

            if (j < o.rows) {
                if (comptime meta.diagOf(X) == .unit) {
                    op_(&o.data[o._index(j, j)], numeric.one(meta.Numeric(X)), y.data[j]);
                } else {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(j, j)], y.data[j])
                    else
                        numeric.set(&o.data[o._index(j, j)], numeric.neg(y.data[j]));
                }
            }

            i = int.min(j + 1, o.rows);
            while (i < o.rows) : (i += 1) {
                o.data[o._index(i, j)] = numeric.zero(meta.Numeric(O));
            }
        }
    } else {
        var i: usize = 0;
        while (i < o.rows) : (i += 1) {
            var j: usize = 0;
            while (j < int.min(i, o.cols)) : (j += 1) {
                o.data[o._index(i, j)] = numeric.zero(meta.Numeric(O));
            }

            if (i < o.cols) {
                if (comptime meta.diagOf(X) == .unit) {
                    op_(&o.data[o._index(i, i)], numeric.one(meta.Numeric(X)), y.data[i]);
                } else {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(i, i)], y.data[i])
                    else
                        numeric.set(&o.data[o._index(i, i)], numeric.neg(y.data[i]));
                }
            }

            j = int.min(i + 1, o.cols);
            while (j < o.cols) : (j += 1) {
                o.data[o._index(i, j)] = numeric.zero(meta.Numeric(O));
            }
        }
    }

    if (comptime meta.layoutOf(X) == .col_major) {
        var j: usize = 0;
        while (j < x.cols) : (j += 1) {
            var p: usize = x.ptr[j];
            while (p < x.ptr[j + 1]) : (p += 1) {
                if (x.idx[p] == j)
                    op_(&o.data[o._index(x.idx[p], j)], x.data[p], y.data[j])
                else
                    numeric.set(&o.data[o._index(x.idx[p], j)], x.data[p]);
            }
        }
    } else {
        var i: usize = 0;
        while (i < x.rows) : (i += 1) {
            var p: usize = x.ptr[i];
            while (p < x.ptr[i + 1]) : (p += 1) {
                if (i == x.idx[p])
                    op_(&o.data[o._index(i, x.idx[p])], x.data[p], y.data[i])
                else
                    numeric.set(&o.data[o._index(i, x.idx[p])], x.data[p]);
            }
        }
    }
}
