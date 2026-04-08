const std = @import("std");

const types = @import("../../../types.zig");

const int = @import("../../../int.zig");

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
    const O: type = types.Child(@TypeOf(o));
    const Y: type = @TypeOf(y);

    const aliased = (comptime O == Y) and std.meta.eql(o.*, y);

    var j: usize = 0;
    while (j < o.cols) : (j += 1) {
        if (comptime types.uploOf(O) == .upper) {
            if ((comptime op_ == numeric.sub_) or !aliased) {
                var i: usize = 0;
                while (i < int.min(j, o.rows)) : (i += 1) {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(i, j)], y.data[y._index(i, j)])
                    else
                        numeric.set(&o.data[o._index(i, j)], numeric.neg(y.data[y._index(i, j)]));
                }
            }

            if (j < o.rows) {
                if (comptime types.diagOf(Y) == .unit)
                    op_(&o.data[o._index(j, j)], x.data[j], numeric.one(types.Numeric(Y)))
                else
                    op_(&o.data[o._index(j, j)], x.data[j], y.data[y._index(j, j)]);
            }
        } else {
            if (j < o.rows) {
                if (comptime types.diagOf(Y) == .unit)
                    op_(&o.data[o._index(j, j)], x.data[j], numeric.one(types.Numeric(Y)))
                else
                    op_(&o.data[o._index(j, j)], x.data[j], y.data[y._index(j, j)]);
            }

            if ((comptime op_ == numeric.sub_) or !aliased) {
                var i: usize = int.min(j + 1, o.rows);
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
    const Y: type = @TypeOf(y);

    const aliased = (comptime O == Y) and std.meta.eql(o.*, y);

    var i: usize = 0;
    while (i < o.rows) : (i += 1) {
        if (comptime types.uploOf(O) == .lower) {
            if ((comptime op_ == numeric.sub_) or !aliased) {
                var j: usize = 0;
                while (j < int.min(i, o.cols)) : (j += 1) {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(i, j)], y.data[y._index(i, j)])
                    else
                        numeric.set(&o.data[o._index(i, j)], numeric.neg(y.data[y._index(i, j)]));
                }
            }

            if (i < o.cols) {
                if (comptime types.diagOf(Y) == .unit)
                    op_(&o.data[o._index(i, i)], x.data[i], numeric.one(types.Numeric(Y)))
                else
                    op_(&o.data[o._index(i, i)], x.data[i], y.data[y._index(i, i)]);
            }
        } else {
            if (i < o.cols) {
                if (comptime types.diagOf(Y) == .unit)
                    op_(&o.data[o._index(i, i)], x.data[i], numeric.one(types.Numeric(Y)))
                else
                    op_(&o.data[o._index(i, i)], x.data[i], y.data[y._index(i, i)]);
            }

            if ((comptime op_ == numeric.sub_) or !aliased) {
                var j: usize = int.min(i + 1, o.cols);
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
