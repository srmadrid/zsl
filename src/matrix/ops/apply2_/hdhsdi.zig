const std = @import("std");

const types = @import("../../../types.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);

    if (comptime types.layoutOf(O) == .col_major) {
        var j: usize = 0;
        while (j < o.cols) : (j += 1) {
            if (comptime types.uploOf(O) == .upper) {
                var i: usize = 0;
                while (i < j) : (i += 1) {
                    o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                }

                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(j, j)], y.data[j])
                else
                    numeric.set(&o.data[o._index(j, j)], numeric.neg(y.data[j]));
            } else {
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(j, j)], y.data[j])
                else
                    numeric.set(&o.data[o._index(j, j)], numeric.neg(y.data[j]));

                var i: usize = j + 1;
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
                while (j < i) : (j += 1) {
                    o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                }

                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(i, i)], y.data[i])
                else
                    numeric.set(&o.data[o._index(i, i)], numeric.neg(y.data[i]));
            } else {
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(i, i)], y.data[i])
                else
                    numeric.set(&o.data[o._index(i, i)], numeric.neg(y.data[i]));

                var j: usize = i + 1;
                while (j < o.cols) : (j += 1) {
                    o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                }
            }
        }
    }

    if (comptime types.layoutOf(X) == .col_major) {
        var j: usize = 0;
        while (j < x.cols) : (j += 1) {
            var p: usize = x.ptr[j];
            while (p < x.ptr[j + 1]) : (p += 1) {
                if (x.idx[p] == j) {
                    op_(&o.data[o._index(x.idx[p], j)], x.data[p], y.data[j]);
                } else {
                    if (comptime types.uploOf(O) == types.uploOf(X))
                        numeric.set(&o.data[o._index(x.idx[p], j)], x.data[p])
                    else
                        numeric.set(&o.data[o._index(j, x.idx[p])], numeric.conj(x.data[p]));
                }
            }
        }
    } else {
        var i: usize = 0;
        while (i < x.rows) : (i += 1) {
            var p: usize = x.ptr[i];
            while (p < x.ptr[i + 1]) : (p += 1) {
                if (i == x.idx[p]) {
                    op_(&o.data[o._index(i, x.idx[p])], x.data[p], y.data[i]);
                } else {
                    if (comptime types.uploOf(O) == types.uploOf(X))
                        numeric.set(&o.data[o._index(i, x.idx[p])], x.data[p])
                    else
                        numeric.set(&o.data[o._index(x.idx[p], i)], numeric.conj(x.data[p]));
                }
            }
        }
    }
}
