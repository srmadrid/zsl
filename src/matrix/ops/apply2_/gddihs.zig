const std = @import("std");

const types = @import("../../../types.zig");
const int = @import("../../../int.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) !void {
    const O: type = types.Child(@TypeOf(o));

    if (o.rows != o.cols or x.rows != x.cols or
        o.rows != x.rows or o.rows != y.size)
        return matrix.Error.DimensionMismatch;

    switch (comptime types.layoutOf(O)) {
        .col_major => return loopColMajor(o, x, y, op_),
        .row_major => return loopRowMajor(o, x, y, op_),
    }
}

inline fn loopColMajor(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));
    const Y: type = @TypeOf(y);

    var j: usize = 0;
    while (j < o.cols) : (j += 1) {
        var i: usize = 0;
        while (i < int.min(j, o.rows)) : (i += 1) {
            o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
        }

        numeric.set(&o.data[o._index(j, j)], x.data[j]);

        i = int.min(j + 1, o.rows);
        while (i < o.rows) : (i += 1) {
            o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
        }
    }

    if (comptime types.layoutOf(Y) == .col_major) {
        j = 0;
        while (j < y.size) : (j += 1) {
            var p: usize = y.ptr[j];
            while (p < y.ptr[j + 1]) : (p += 1) {
                op_(&o.data[o._index(y.idx[p], j)], o.data[o._index(y.idx[p], j)], y.data[p]);

                if (y.idx[p] != j) {
                    op_(&o.data[o._index(j, y.idx[p])], o.data[o._index(j, y.idx[p])], numeric.conj(y.data[p]));
                }
            }
        }
    } else {
        var i: usize = 0;
        while (i < y.size) : (i += 1) {
            var p: usize = y.ptr[i];
            while (p < y.ptr[i + 1]) : (p += 1) {
                op_(&o.data[o._index(i, y.idx[p])], o.data[o._index(i, y.idx[p])], y.data[p]);

                if (i != y.idx[p]) {
                    op_(&o.data[o._index(y.idx[p], i)], o.data[o._index(y.idx[p], i)], numeric.conj(y.data[p]));
                }
            }
        }
    }
}

inline fn loopRowMajor(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));
    const Y: type = @TypeOf(y);

    var i: usize = 0;
    while (i < o.rows) : (i += 1) {
        var j: usize = 0;
        while (j < int.min(i, o.cols)) : (j += 1) {
            o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
        }

        numeric.set(&o.data[o._index(i, i)], x.data[i]);

        j = int.min(i + 1, o.cols);
        while (j < o.cols) : (j += 1) {
            o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
        }
    }

    if (comptime types.layoutOf(Y) == .col_major) {
        var j: usize = 0;
        while (j < y.size) : (j += 1) {
            var p: usize = y.ptr[j];
            while (p < y.ptr[j + 1]) : (p += 1) {
                op_(&o.data[o._index(y.idx[p], j)], o.data[o._index(y.idx[p], j)], y.data[p]);

                if (y.idx[p] != j) {
                    op_(&o.data[o._index(j, y.idx[p])], o.data[o._index(j, y.idx[p])], numeric.conj(y.data[p]));
                }
            }
        }
    } else {
        i = 0;
        while (i < y.size) : (i += 1) {
            var p: usize = y.ptr[i];
            while (p < y.ptr[i + 1]) : (p += 1) {
                op_(&o.data[o._index(i, y.idx[p])], o.data[o._index(i, y.idx[p])], y.data[p]);

                if (i != y.idx[p]) {
                    op_(&o.data[o._index(y.idx[p], i)], o.data[o._index(y.idx[p], i)], numeric.conj(y.data[p]));
                }
            }
        }
    }
}
