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
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    const aliased = (comptime O == Y) and std.meta.eql(o.*, y);

    var j: usize = 0;
    while (j < o.cols) : (j += 1) {
        var i: usize = 0;
        if (comptime types.uploOf(X) == .upper) {
            while (i < int.min(j, o.rows)) : (i += 1) {
                op_(&o.data[o._index(i, j)], x.data[x._index(i, j)], y.data[y._index(i, j)]);
            }
        } else {
            if ((comptime op_ == numeric.sub_) or !aliased) {
                while (i < int.min(j, o.rows)) : (i += 1) {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(i, j)], y.data[y._index(i, j)])
                    else
                        numeric.set(&o.data[o._index(i, j)], numeric.neg(y.data[y._index(i, j)]));
                }
            }
        }

        if (j < o.rows) {
            if (comptime types.diagOf(X) == .unit)
                op_(&o.data[o._index(j, j)], numeric.one(types.Numeric(X)), y.data[y._index(j, j)])
            else
                op_(&o.data[o._index(j, j)], x.data[x._index(j, j)], y.data[y._index(j, j)]);
        }

        i = int.min(j + 1, o.rows);
        if (comptime types.uploOf(X) == .lower) {
            while (i < o.rows) : (i += 1) {
                op_(&o.data[o._index(i, j)], x.data[x._index(i, j)], y.data[y._index(i, j)]);
            }
        } else {
            if ((comptime op_ == numeric.sub_) or !aliased) {
                while (i < o.rows) : (i += 1) {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(i, j)], y.data[y._index(i, j)])
                    else
                        numeric.set(&o.data[o._index(i, j)], numeric.neg(y.data[y._index(i, j)]));
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

    var i: usize = 0;
    while (i < o.rows) : (i += 1) {
        var j: usize = 0;
        if (comptime types.uploOf(X) == .lower) {
            while (j < int.min(i, o.cols)) : (j += 1) {
                op_(&o.data[o._index(i, j)], x.data[x._index(i, j)], y.data[y._index(i, j)]);
            }
        } else {
            if ((comptime op_ == numeric.sub_) or !aliased) {
                while (j < int.min(i, o.cols)) : (j += 1) {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(i, j)], y.data[y._index(i, j)])
                    else
                        numeric.set(&o.data[o._index(i, j)], numeric.neg(y.data[y._index(i, j)]));
                }
            }
        }

        if (i < o.cols) {
            if (comptime types.diagOf(X) == .unit)
                op_(&o.data[o._index(i, i)], numeric.one(types.Numeric(X)), y.data[y._index(i, i)])
            else
                op_(&o.data[o._index(i, i)], x.data[x._index(i, i)], y.data[y._index(i, i)]);
        }

        j = int.min(i + 1, o.cols);
        if (comptime types.uploOf(X) == .upper) {
            while (j < o.cols) : (j += 1) {
                op_(&o.data[o._index(i, j)], x.data[x._index(i, j)], y.data[y._index(i, j)]);
            }
        } else {
            if ((comptime op_ == numeric.sub_) or !aliased) {
                while (j < o.cols) : (j += 1) {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(i, j)], y.data[y._index(i, j)])
                    else
                        numeric.set(&o.data[o._index(i, j)], numeric.neg(y.data[y._index(i, j)]));
                }
            }
        }
    }
}
