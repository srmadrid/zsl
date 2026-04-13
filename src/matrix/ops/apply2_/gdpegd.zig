const std = @import("std");

const types = @import("../../../types.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    const aliased = (comptime O == Y) and std.meta.eql(o.*, y);

    if ((comptime op_ == numeric.sub_) or !aliased) {
        if (comptime types.layoutOf(O) == .col_major) {
            var j: usize = 0;
            while (j < o.cols) : (j += 1) {
                var i: usize = 0;
                while (i < o.rows) : (i += 1) {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(i, j)], y.data[y._index(i, j)])
                    else
                        numeric.set(&o.data[o._index(i, j)], numeric.neg(y.data[y._index(i, j)]));
                }
            }
        } else {
            var i: usize = 0;
            while (i < o.rows) : (i += 1) {
                var j: usize = 0;
                while (j < o.cols) : (j += 1) {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(i, j)], y.data[y._index(i, j)])
                    else
                        numeric.set(&o.data[o._index(i, j)], numeric.neg(y.data[y._index(i, j)]));
                }
            }
        }
    }

    var k: usize = 0;
    while (k < x.rows) : (k += 1) {
        const i_o = if (x.direction == .forward) k else x.data[k];
        const j_o = if (x.direction == .forward) x.data[k] else k;

        if ((comptime op_ == numeric.add_) or !aliased)
            op_(&o.data[o._index(i_o, j_o)], numeric.one(types.Numeric(X)), y.data[y._index(i_o, j_o)])
        else
            op_(&o.data[o._index(i_o, j_o)], numeric.one(types.Numeric(X)), numeric.neg(y.data[y._index(i_o, j_o)]));
    }
}
