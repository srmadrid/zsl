const std = @import("std");

const types = @import("../../../types.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) !void {
    const O: type = types.Child(@TypeOf(o));

    if (o.rows != o.cols or y.rows != y.cols or
        o.rows != x.size or o.rows != y.rows)
        return matrix.Error.DimensionMismatch;

    switch (comptime types.layoutOf(O)) {
        .col_major => return loopColMajor(o, x, y, op_),
        .row_major => return loopRowMajor(o, x, y, op_),
    }
}

inline fn loopColMajor(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    const aliased = (comptime O == Y) and std.meta.eql(o.*, y);

    if ((comptime op_ == numeric.sub_) or !aliased) {
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
    }

    if (comptime types.layoutOf(X) == .col_major) {
        var j: usize = 0;
        while (j < x.size) : (j += 1) {
            var p: usize = x.ptr[j];
            while (p < x.ptr[j + 1]) : (p += 1) {
                numeric.add_(&o.data[o._index(x.idx[p], j)], x.data[p], o.data[o._index(x.idx[p], j)]);

                if (x.idx[p] != j) {
                    numeric.add_(&o.data[o._index(j, x.idx[p])], numeric.conj(x.data[p]), o.data[o._index(j, x.idx[p])]);
                }
            }
        }
    } else {
        var i: usize = 0;
        while (i < x.size) : (i += 1) {
            var p: usize = x.ptr[i];
            while (p < x.ptr[i + 1]) : (p += 1) {
                numeric.add_(&o.data[o._index(i, x.idx[p])], x.data[p], o.data[o._index(i, x.idx[p])]);

                if (i != x.idx[p]) {
                    numeric.add_(&o.data[o._index(x.idx[p], i)], numeric.conj(x.data[p]), o.data[o._index(x.idx[p], i)]);
                }
            }
        }
    }
}

inline fn loopRowMajor(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    const aliased = (comptime O == Y) and std.meta.eql(o.*, y);

    if ((comptime op_ == numeric.sub_) or !aliased) {
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

    if (comptime types.layoutOf(X) == .col_major) {
        var j: usize = 0;
        while (j < x.size) : (j += 1) {
            var p: usize = x.ptr[j];
            while (p < x.ptr[j + 1]) : (p += 1) {
                numeric.add_(&o.data[o._index(x.idx[p], j)], x.data[p], o.data[o._index(x.idx[p], j)]);

                if (x.idx[p] != j) {
                    numeric.add_(&o.data[o._index(j, x.idx[p])], numeric.conj(x.data[p]), o.data[o._index(j, x.idx[p])]);
                }
            }
        }
    } else {
        var i: usize = 0;
        while (i < x.size) : (i += 1) {
            var p: usize = x.ptr[i];
            while (p < x.ptr[i + 1]) : (p += 1) {
                numeric.add_(&o.data[o._index(i, x.idx[p])], x.data[p], o.data[o._index(i, x.idx[p])]);

                if (i != x.idx[p]) {
                    numeric.add_(&o.data[o._index(x.idx[p], i)], numeric.conj(x.data[p]), o.data[o._index(x.idx[p], i)]);
                }
            }
        }
    }
}
