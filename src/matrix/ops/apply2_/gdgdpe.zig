const std = @import("std");

const meta = @import("../../../meta.zig");

const numeric = @import("../../../numeric.zig");

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

    var k: usize = 0;
    while (k < y.rows) : (k += 1) {
        const i = if (y.direction == .forward) k else y.data[k];
        const j = if (y.direction == .forward) y.data[k] else k;

        op_(&o.data[o._index(i, j)], x.data[x._index(i, j)], numeric.one(meta.Numeric(Y)));
    }
}
