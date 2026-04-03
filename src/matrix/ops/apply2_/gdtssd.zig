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
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    var j: usize = 0;
    while (j < o.cols) : (j += 1) {
        if (comptime types.uploOf(Y) == .upper) {
            var i: usize = 0;
            while (i < j) : (i += 1) {
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(i, j)], y.data[y._index(i, j)])
                else
                    numeric.set(&o.data[o._index(i, j)], numeric.neg(y.data[y._index(i, j)]));
            }

            if (comptime types.diagOf(X) == .unit) {
                op_(&o.data[o._index(j, j)], numeric.one(types.Numeric(X)), y.data[y._index(j, j)]);
            } else {
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(j, j)], y.data[y._index(j, j)])
                else
                    numeric.set(&o.data[o._index(j, j)], numeric.neg(y.data[y._index(j, j)]));
            }

            i = j + 1;
            while (i < o.rows) : (i += 1) {
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(i, j)], y.data[y._index(j, i)])
                else
                    numeric.set(&o.data[o._index(i, j)], numeric.neg(y.data[y._index(j, i)]));
            }
        } else {
            var i: usize = 0;
            while (i < j) : (i += 1) {
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(i, j)], y.data[y._index(j, i)])
                else
                    numeric.set(&o.data[o._index(i, j)], numeric.neg(y.data[y._index(j, i)]));
            }

            if (comptime types.diagOf(X) == .unit) {
                op_(&o.data[o._index(j, j)], numeric.one(types.Numeric(X)), y.data[y._index(j, j)]);
            } else {
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(j, j)], y.data[y._index(j, j)])
                else
                    numeric.set(&o.data[o._index(j, j)], numeric.neg(y.data[y._index(j, j)]));
            }

            i = j + 1;
            while (i < o.rows) : (i += 1) {
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(i, j)], y.data[y._index(i, j)])
                else
                    numeric.set(&o.data[o._index(i, j)], numeric.neg(y.data[y._index(i, j)]));
            }
        }
    }

    if (comptime types.layoutOf(X) == .col_major) {
        j = 0;
        while (j < x.cols) : (j += 1) {
            var p: usize = x.ptr[j];
            while (p < x.ptr[j + 1]) : (p += 1) {
                numeric.add_(&o.data[o._index(x.idx[p], j)], x.data[p], o.data[o._index(x.idx[p], j)]);
            }
        }
    } else {
        var i: usize = 0;
        while (i < x.rows) : (i += 1) {
            var p: usize = x.ptr[i];
            while (p < x.ptr[i + 1]) : (p += 1) {
                numeric.add_(&o.data[o._index(i, x.idx[p])], x.data[p], o.data[o._index(i, x.idx[p])]);
            }
        }
    }
}

inline fn loopRowMajor(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    var i: usize = 0;
    while (i < o.rows) : (i += 1) {
        if (comptime types.uploOf(Y) == .lower) {
            var j: usize = 0;
            while (j < i) : (j += 1) {
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(i, j)], y.data[y._index(i, j)])
                else
                    numeric.set(&o.data[o._index(i, j)], numeric.neg(y.data[y._index(i, j)]));
            }

            if (comptime types.diagOf(X) == .unit) {
                op_(&o.data[o._index(i, i)], numeric.one(types.Numeric(X)), y.data[y._index(i, i)]);
            } else {
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(i, i)], y.data[y._index(i, i)])
                else
                    numeric.set(&o.data[o._index(i, i)], numeric.neg(y.data[y._index(i, i)]));
            }

            j = i + 1;
            while (j < o.cols) : (j += 1) {
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(i, j)], y.data[y._index(j, i)])
                else
                    numeric.set(&o.data[o._index(i, j)], numeric.neg(y.data[y._index(j, i)]));
            }
        } else {
            var j: usize = 0;
            while (j < i) : (j += 1) {
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(i, j)], y.data[y._index(j, i)])
                else
                    numeric.set(&o.data[o._index(i, j)], numeric.neg(y.data[y._index(j, i)]));
            }

            if (comptime types.diagOf(X) == .unit) {
                op_(&o.data[o._index(i, i)], numeric.one(types.Numeric(X)), y.data[y._index(i, i)]);
            } else {
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(i, i)], y.data[y._index(i, i)])
                else
                    numeric.set(&o.data[o._index(i, i)], numeric.neg(y.data[y._index(i, i)]));
            }

            j = i + 1;
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
        while (j < x.cols) : (j += 1) {
            var p: usize = x.ptr[j];
            while (p < x.ptr[j + 1]) : (p += 1) {
                numeric.add_(&o.data[o._index(x.idx[p], j)], x.data[p], o.data[o._index(x.idx[p], j)]);
            }
        }
    } else {
        i = 0;
        while (i < x.rows) : (i += 1) {
            var p: usize = x.ptr[i];
            while (p < x.ptr[i + 1]) : (p += 1) {
                numeric.add_(&o.data[o._index(i, x.idx[p])], x.data[p], o.data[o._index(i, x.idx[p])]);
            }
        }
    }
}
