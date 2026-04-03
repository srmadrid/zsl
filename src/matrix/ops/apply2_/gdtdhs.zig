const std = @import("std");

const types = @import("../../../types.zig");
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
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    var j: usize = 0;
    while (j < o.cols) : (j += 1) {
        if (comptime types.uploOf(X) == .upper) {
            var i: usize = 0;
            while (i < j) : (i += 1) {
                numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
            }

            if (comptime types.diagOf(X) == .unit)
                numeric.set(&o.data[o._index(j, j)], numeric.one(types.Numeric(O)))
            else
                numeric.set(&o.data[o._index(j, j)], x.data[x._index(j, j)]);

            i = j + 1;
            while (i < o.rows) : (i += 1) {
                o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
            }
        } else {
            var i: usize = 0;
            while (i < j) : (i += 1) {
                o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
            }

            if (comptime types.diagOf(X) == .unit)
                numeric.set(&o.data[o._index(j, j)], numeric.one(types.Numeric(O)))
            else
                numeric.set(&o.data[o._index(j, j)], x.data[x._index(j, j)]);

            i = j + 1;
            while (i < o.rows) : (i += 1) {
                numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
            }
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
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    var i: usize = 0;
    while (i < o.rows) : (i += 1) {
        if (comptime types.uploOf(X) == .lower) {
            var j: usize = 0;
            while (j < i) : (j += 1) {
                numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
            }

            if (comptime types.diagOf(X) == .unit)
                numeric.set(&o.data[o._index(i, i)], numeric.one(types.Numeric(O)))
            else
                numeric.set(&o.data[o._index(i, i)], x.data[x._index(i, i)]);

            j = i + 1;
            while (j < o.cols) : (j += 1) {
                o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
            }
        } else {
            var j: usize = 0;
            while (j < i) : (j += 1) {
                o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
            }

            if (comptime types.diagOf(X) == .unit)
                numeric.set(&o.data[o._index(i, i)], numeric.one(types.Numeric(O)))
            else
                numeric.set(&o.data[o._index(i, i)], x.data[x._index(i, i)]);

            j = i + 1;
            while (j < o.cols) : (j += 1) {
                numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
            }
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
