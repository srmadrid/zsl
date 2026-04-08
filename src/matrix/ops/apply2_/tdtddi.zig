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
    const X: type = @TypeOf(x);

    const aliased = (comptime O == X) and std.meta.eql(o.*, x);

    var j: usize = 0;
    while (j < o.cols) : (j += 1) {
        if (comptime types.uploOf(O) == .upper) {
            if (!aliased) {
                var i: usize = 0;
                while (i < int.min(j, o.rows)) : (i += 1) {
                    numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                }
            }

            if (j < o.rows) {
                if (comptime types.diagOf(X) == .unit)
                    op_(&o.data[o._index(j, j)], numeric.one(types.Numeric(X)), y.data[j])
                else
                    op_(&o.data[o._index(j, j)], x.data[x._index(j, j)], y.data[j]);
            }
        } else {
            if (j < o.rows) {
                if (comptime types.diagOf(X) == .unit)
                    op_(&o.data[o._index(j, j)], numeric.one(types.Numeric(X)), y.data[j])
                else
                    op_(&o.data[o._index(j, j)], x.data[x._index(j, j)], y.data[j]);
            }

            if (!aliased) {
                var i: usize = int.min(j + 1, o.rows);
                while (i < o.rows) : (i += 1) {
                    numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                }
            }
        }
    }
}

inline fn loopRowMajor(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);

    const aliased = (comptime O == X) and std.meta.eql(o.*, x);

    var i: usize = 0;
    while (i < o.rows) : (i += 1) {
        if (comptime types.uploOf(O) == .lower) {
            if (!aliased) {
                var j: usize = 0;
                while (j < int.min(i, o.cols)) : (j += 1) {
                    numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                }
            }

            if (i < o.cols) {
                if (comptime types.diagOf(X) == .unit)
                    op_(&o.data[o._index(i, i)], numeric.one(types.Numeric(X)), y.data[i])
                else
                    op_(&o.data[o._index(i, i)], x.data[x._index(i, i)], y.data[i]);
            }
        } else {
            if (i < o.cols) {
                if (comptime types.diagOf(X) == .unit)
                    op_(&o.data[o._index(i, i)], numeric.one(types.Numeric(X)), y.data[i])
                else
                    op_(&o.data[o._index(i, i)], x.data[x._index(i, i)], y.data[i]);
            }

            if (!aliased) {
                var j: usize = int.min(i + 1, o.cols);
                while (j < o.cols) : (j += 1) {
                    numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                }
            }
        }
    }
}
