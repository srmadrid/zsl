const std = @import("std");

const meta = @import("../../../meta.zig");
const int = @import("../../../int.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = meta.Child(@TypeOf(o));
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    const aliased = (comptime O == X) and std.meta.eql(o.*, x);

    if (!aliased) {
        if (comptime meta.layoutOf(O) == .col_major) {
            var j: usize = 0;
            while (j < o.cols) : (j += 1) {
                var i: usize = 0;
                while (i < o.rows) : (i += 1) {
                    numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                }
            }
        } else {
            var i: usize = 0;
            while (i < o.rows) : (i += 1) {
                var j: usize = 0;
                while (j < o.cols) : (j += 1) {
                    numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                }
            }
        }
    }

    if (comptime meta.diagOf(Y) == .unit) {
        var i: usize = 0;
        while (i < int.min(o.rows, o.cols)) : (i += 1) {
            op_(&o.data[o._index(i, i)], x.data[x._index(i, i)], numeric.one(meta.Numeric(Y)));
        }
    }

    if (comptime meta.layoutOf(Y) == .col_major) {
        var j: usize = 0;
        while (j < y.cols) : (j += 1) {
            var p: usize = y.ptr[j];
            while (p < y.ptr[j + 1]) : (p += 1) {
                op_(&o.data[o._index(y.idx[p], j)], x.data[x._index(y.idx[p], j)], y.data[p]);
            }
        }
    } else {
        var i: usize = 0;
        while (i < y.rows) : (i += 1) {
            var p: usize = y.ptr[i];
            while (p < y.ptr[i + 1]) : (p += 1) {
                op_(&o.data[o._index(i, y.idx[p])], x.data[x._index(i, y.idx[p])], y.data[p]);
            }
        }
    }
}
