const std = @import("std");

const types = @import("../../../types.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) !void {
    const O: type = types.Child(@TypeOf(o));

    if (x.rows != x.cols or o.size != x.rows or o.size != y.size)
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
    while (j < o.size) : (j += 1) {
        if (comptime types.uploOf(O) == .upper) {
            var i: usize = 0;
            while (i < j) : (i += 1) {
                o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
            }

            numeric.set(&o.data[o._index(j, j)], x.data[j]);
        } else {
            numeric.set(&o.data[o._index(j, j)], x.data[j]);

            var i: usize = j + 1;
            while (i < o.size) : (i += 1) {
                o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
            }
        }
    }

    if (comptime types.layoutOf(Y) == .col_major) {
        j = 0;
        while (j < y.size) : (j += 1) {
            var p: usize = y.ptr[j];
            while (p < y.ptr[j + 1]) : (p += 1) {
                if (comptime types.uploOf(O) == types.uploOf(Y))
                    op_(&o.data[o._index(y.idx[p], j)], o.data[o._index(y.idx[p], j)], y.data[p])
                else
                    op_(&o.data[o._index(j, y.idx[p])], o.data[o._index(j, y.idx[p])], y.data[p]);
            }
        }
    } else {
        var i: usize = 0;
        while (i < y.size) : (i += 1) {
            var p: usize = y.ptr[i];
            while (p < y.ptr[i + 1]) : (p += 1) {
                if (comptime types.uploOf(O) == types.uploOf(Y))
                    op_(&o.data[o._index(i, y.idx[p])], o.data[o._index(i, y.idx[p])], y.data[p])
                else
                    op_(&o.data[o._index(y.idx[p], i)], o.data[o._index(y.idx[p], i)], y.data[p]);
            }
        }
    }
}

inline fn loopRowMajor(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));
    const Y: type = @TypeOf(y);

    var i: usize = 0;
    while (i < o.size) : (i += 1) {
        if (comptime types.uploOf(O) == .lower) {
            var j: usize = 0;
            while (j < i) : (j += 1) {
                o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
            }

            numeric.set(&o.data[o._index(i, i)], x.data[i]);
        } else {
            numeric.set(&o.data[o._index(i, i)], x.data[i]);

            var j: usize = i + 1;
            while (j < o.size) : (j += 1) {
                o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
            }
        }
    }

    if (comptime types.layoutOf(Y) == .col_major) {
        var j: usize = 0;
        while (j < y.size) : (j += 1) {
            var p: usize = y.ptr[j];
            while (p < y.ptr[j + 1]) : (p += 1) {
                if (comptime types.uploOf(O) == types.uploOf(Y))
                    op_(&o.data[o._index(y.idx[p], j)], o.data[o._index(y.idx[p], j)], y.data[p])
                else
                    op_(&o.data[o._index(j, y.idx[p])], o.data[o._index(j, y.idx[p])], y.data[p]);
            }
        }
    } else {
        i = 0;
        while (i < y.size) : (i += 1) {
            var p: usize = y.ptr[i];
            while (p < y.ptr[i + 1]) : (p += 1) {
                if (comptime types.uploOf(O) == types.uploOf(Y))
                    op_(&o.data[o._index(i, y.idx[p])], o.data[o._index(i, y.idx[p])], y.data[p])
                else
                    op_(&o.data[o._index(y.idx[p], i)], o.data[o._index(y.idx[p], i)], y.data[p]);
            }
        }
    }
}
