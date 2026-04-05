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

    const aliased = (comptime O == Y) and std.meta.eql(o.*, y);

    if ((comptime op_ == numeric.sub_) or !aliased) {
        if (comptime types.layoutOf(O) == .col_major) {
            var j: usize = 0;
            while (j < o.cols) : (j += 1) {
                var i: usize = 0;
                while (i < o.rows) : (i += 1) {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(i, j)], y.data[y._index(i, j)])
                    else
                        numeric.set(&o.data[o._index(i, j)], numeric.neg(y.data[y._index(i, j)]));
                }
            }
        } else {
            var i: usize = 0;
            while (i < o.rows) : (i += 1) {
                var j: usize = 0;
                while (j < o.cols) : (j += 1) {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(i, j)], y.data[y._index(i, j)])
                    else
                        numeric.set(&o.data[o._index(i, j)], numeric.neg(y.data[y._index(i, j)]));
                }
            }
        }
    }

    if (comptime types.layoutOf(X) == .col_major) {
        var j: usize = 0;
        while (j < x.size) : (j += 1) {
            var p: usize = x.ptr[j];
            while (p < x.ptr[j + 1]) : (p += 1) {
                if ((comptime op_ == numeric.add_) or !aliased) {
                    op_(&o.data[o._index(x.idx[p], j)], x.data[p], y.data[y._index(x.idx[p], j)]);

                    if (x.idx[p] != j) {
                        op_(&o.data[o._index(j, x.idx[p])], numeric.conj(x.data[p]), y.data[y._index(j, x.idx[p])]);
                    }
                } else {
                    op_(&o.data[o._index(x.idx[p], j)], x.data[p], numeric.neg(y.data[y._index(x.idx[p], j)]));

                    if (x.idx[p] != j) {
                        op_(&o.data[o._index(j, x.idx[p])], numeric.conj(x.data[p]), numeric.neg(y.data[y._index(j, x.idx[p])]));
                    }
                }
            }
        }
    } else {
        var i: usize = 0;
        while (i < x.size) : (i += 1) {
            var p: usize = x.ptr[i];
            while (p < x.ptr[i + 1]) : (p += 1) {
                if ((comptime op_ == numeric.add_) or !aliased) {
                    op_(&o.data[o._index(i, x.idx[p])], x.data[p], y.data[y._index(i, x.idx[p])]);

                    if (i != x.idx[p]) {
                        op_(&o.data[o._index(x.idx[p], i)], numeric.conj(x.data[p]), y.data[y._index(x.idx[p], i)]);
                    }
                } else {
                    op_(&o.data[o._index(i, x.idx[p])], x.data[p], numeric.neg(y.data[y._index(i, x.idx[p])]));

                    if (i != x.idx[p]) {
                        op_(&o.data[o._index(x.idx[p], i)], numeric.conj(x.data[p]), numeric.neg(y.data[y._index(x.idx[p], i)]));
                    }
                }
            }
        }
    }
}
