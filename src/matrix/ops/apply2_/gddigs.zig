const std = @import("std");

const types = @import("../../../types.zig");
const int = @import("../../../int.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) !void {
    const O: type = types.Child(@TypeOf(o));

    if (o.rows != x.rows or o.cols != x.cols or
        o.rows != y.rows or o.cols != y.cols)
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
        while (j < y.cols) : (j += 1) {
            var p: usize = y.ptr[j];
            while (p < y.ptr[j + 1]) : (p += 1) {
                op_(&o.data[o._index(y.idx[p], j)], o.data[o._index(y.idx[p], j)], y.data[p]);
            }
        }
    } else {
        i = 0;
        while (i < y.rows) : (i += 1) {
            var p: usize = y.ptr[i];
            while (p < y.ptr[i + 1]) : (p += 1) {
                op_(&o.data[o._index(i, y.idx[p])], o.data[o._index(i, y.idx[p])], y.data[p]);
            }
        }
    }
}
