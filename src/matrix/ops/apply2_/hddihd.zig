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

    const aliased = (comptime O == Y) and std.meta.eql(o.*, y);

    var j: usize = 0;
    while (j < o.size) : (j += 1) {
        if (comptime types.uploOf(O) == .upper) {
            if ((comptime op_ == numeric.sub_) or !aliased) {
                var i: usize = 0;
                while (i < j) : (i += 1) {
                    const ty = if (comptime types.uploOf(Y) == .upper) y.data[y._index(i, j)] else numeric.conj(y.data[y._index(j, i)]);
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(i, j)], ty)
                    else
                        numeric.set(&o.data[o._index(i, j)], numeric.neg(ty));
                }
            }

            op_(&o.data[o._index(j, j)], x.data[j], y.data[y._index(j, j)]);
        } else {
            op_(&o.data[o._index(j, j)], x.data[j], y.data[y._index(j, j)]);

            if ((comptime op_ == numeric.sub_) or !aliased) {
                var i: usize = j + 1;
                while (i < o.size) : (i += 1) {
                    const ty = if (comptime types.uploOf(Y) == .lower) y.data[y._index(i, j)] else numeric.conj(y.data[y._index(j, i)]);
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(i, j)], ty)
                    else
                        numeric.set(&o.data[o._index(i, j)], numeric.neg(ty));
                }
            }
        }
    }
}

inline fn loopRowMajor(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));
    const Y: type = @TypeOf(y);

    const aliased = (comptime O == Y) and std.meta.eql(o.*, y);

    var i: usize = 0;
    while (i < o.size) : (i += 1) {
        if (comptime types.uploOf(O) == .lower) {
            if ((comptime op_ == numeric.sub_) or !aliased) {
                var j: usize = 0;
                while (j < i) : (j += 1) {
                    const ty = if (comptime types.uploOf(Y) == .lower) y.data[y._index(i, j)] else numeric.conj(y.data[y._index(j, i)]);
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(i, j)], ty)
                    else
                        numeric.set(&o.data[o._index(i, j)], numeric.neg(ty));
                }
            }

            op_(&o.data[o._index(i, i)], x.data[i], y.data[y._index(i, i)]);
        } else {
            op_(&o.data[o._index(i, i)], x.data[i], y.data[y._index(i, i)]);

            if ((comptime op_ == numeric.sub_) or !aliased) {
                var j: usize = i + 1;
                while (j < o.size) : (j += 1) {
                    const ty = if (comptime types.uploOf(Y) == .upper) y.data[y._index(i, j)] else numeric.conj(y.data[y._index(j, i)]);
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(i, j)], ty)
                    else
                        numeric.set(&o.data[o._index(i, j)], numeric.neg(ty));
                }
            }
        }
    }
}
