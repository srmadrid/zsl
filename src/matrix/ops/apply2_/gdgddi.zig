const std = @import("std");

const types = @import("../../../types.zig");

const int = @import("../../../int.zig");

const numeric = @import("../../../numeric.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);

    const aliased = (comptime O == X) and std.meta.eql(o.*, x);

    if (comptime types.layoutOf(O) == .col_major) {
        var j: usize = 0;
        while (j < o.cols) : (j += 1) {
            var i: usize = 0;
            if (!aliased) {
                while (i < int.min(j, o.rows)) : (i += 1) {
                    numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                }
            }

            if (j < o.rows) {
                op_(&o.data[o._index(j, j)], x.data[x._index(j, j)], y.data[j]);
            }

            i = int.min(j + 1, o.rows);
            if (!aliased) {
                while (i < o.rows) : (i += 1) {
                    numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                }
            }
        }
    } else {
        var i: usize = 0;
        while (i < o.rows) : (i += 1) {
            var j: usize = 0;
            if (!aliased) {
                while (j < int.min(i, o.cols)) : (j += 1) {
                    numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                }
            }

            if (i < o.cols) {
                op_(&o.data[o._index(i, i)], x.data[x._index(i, i)], y.data[i]);
            }

            j = int.min(i + 1, o.cols);
            if (!aliased) {
                while (j < o.cols) : (j += 1) {
                    numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                }
            }
        }
    }
}
