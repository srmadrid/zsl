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

    var j: usize = 0;
    while (j < o.cols) : (j += 1) {
        var i: usize = 0;
        while (i < j) : (i += 1) {
            o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
        }

        if (comptime op_ == numeric.add_)
            numeric.set(&o.data[o._index(j, j)], y.data[j])
        else
            numeric.set(&o.data[o._index(j, j)], numeric.neg(y.data[j]));

        i = j + 1;
        while (i < o.rows) : (i += 1) {
            o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
        }
    }

    if (comptime types.layoutOf(X) == .col_major) {
        j = 0;
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

    var i: usize = 0;
    while (i < o.rows) : (i += 1) {
        var j: usize = 0;
        while (j < i) : (j += 1) {
            o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
        }

        if (comptime op_ == numeric.add_)
            numeric.set(&o.data[o._index(i, i)], y.data[i])
        else
            numeric.set(&o.data[o._index(i, i)], numeric.neg(y.data[i]));

        j = i + 1;
        while (j < o.cols) : (j += 1) {
            o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
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
        i = 0;
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
