const std = @import("std");

const types = @import("../../../types.zig");

const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));

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
        var i: usize = 0;
        if (comptime types.uploOf(X) == .upper) {
            while (i < j) : (i += 1) {
                const ty = if (comptime types.uploOf(Y) == .upper) y.data[y._index(i, j)] else numeric.conj(y.data[y._index(j, i)]);
                op_(&o.data[o._index(i, j)], x.data[x._index(i, j)], ty);
            }
        } else {
            while (i < j) : (i += 1) {
                const ty = if (comptime types.uploOf(Y) == .upper) y.data[y._index(i, j)] else numeric.conj(y.data[y._index(j, i)]);
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(i, j)], ty)
                else
                    numeric.set(&o.data[o._index(i, j)], numeric.neg(ty));
            }
        }

        if (comptime types.diagOf(X) == .unit)
            op_(&o.data[o._index(j, j)], numeric.one(types.Numeric(X)), y.data[y._index(j, j)])
        else
            op_(&o.data[o._index(j, j)], x.data[x._index(j, j)], y.data[y._index(j, j)]);

        i = j + 1;
        if (comptime types.uploOf(X) == .lower) {
            while (i < o.rows) : (i += 1) {
                const ty = if (comptime types.uploOf(Y) == .lower) y.data[y._index(i, j)] else numeric.conj(y.data[y._index(j, i)]);
                op_(&o.data[o._index(i, j)], x.data[x._index(i, j)], ty);
            }
        } else {
            while (i < o.rows) : (i += 1) {
                const ty = if (comptime types.uploOf(Y) == .lower) y.data[y._index(i, j)] else numeric.conj(y.data[y._index(j, i)]);
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(i, j)], ty)
                else
                    numeric.set(&o.data[o._index(i, j)], numeric.neg(ty));
            }
        }
    }
}

inline fn loopRowMajor(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    var i: usize = 0;
    while (i < o.rows) : (i += 1) {
        var j: usize = 0;
        if (comptime types.uploOf(X) == .lower) {
            while (j < i) : (j += 1) {
                const ty = if (comptime types.uploOf(Y) == .lower) y.data[y._index(i, j)] else numeric.conj(y.data[y._index(j, i)]);
                op_(&o.data[o._index(i, j)], x.data[x._index(i, j)], ty);
            }
        } else {
            while (j < i) : (j += 1) {
                const ty = if (comptime types.uploOf(Y) == .lower) y.data[y._index(i, j)] else numeric.conj(y.data[y._index(j, i)]);
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(i, j)], ty)
                else
                    numeric.set(&o.data[o._index(i, j)], numeric.neg(ty));
            }
        }

        if (comptime types.diagOf(X) == .unit)
            op_(&o.data[o._index(i, i)], numeric.one(types.Numeric(X)), y.data[y._index(i, i)])
        else
            op_(&o.data[o._index(i, i)], x.data[x._index(i, i)], y.data[y._index(i, i)]);

        j = i + 1;
        if (comptime types.uploOf(X) == .upper) {
            while (j < o.cols) : (j += 1) {
                const ty = if (comptime types.uploOf(Y) == .upper) y.data[y._index(i, j)] else numeric.conj(y.data[y._index(j, i)]);
                op_(&o.data[o._index(i, j)], x.data[x._index(i, j)], ty);
            }
        } else {
            while (j < o.cols) : (j += 1) {
                const ty = if (comptime types.uploOf(Y) == .upper) y.data[y._index(i, j)] else numeric.conj(y.data[y._index(j, i)]);
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(i, j)], ty)
                else
                    numeric.set(&o.data[o._index(i, j)], numeric.neg(ty));
            }
        }
    }
}
