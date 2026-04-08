const std = @import("std");

const types = @import("../../../types.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O = types.Child(@TypeOf(o));
    const X = @TypeOf(x);
    const Y = @TypeOf(y);

    if (comptime types.layoutOf(O) == .col_major) {
        var j: usize = 0;
        while (j < o.cols) : (j += 1) {
            var i: usize = 0;
            while (i < o.rows) : (i += 1) {
                op_(&o.data[o._index(i, j)], numeric.zero(types.Numeric(X)), numeric.zero(types.Numeric(Y)));
            }

            if (j < o.rows) {
                op_(&o.data[o._index(j, j)], x.data[j], numeric.zero(types.Numeric(Y)));
            }
        }
    } else {
        var i: usize = 0;
        while (i < o.rows) : (i += 1) {
            var j: usize = 0;
            while (j < o.cols) : (j += 1) {
                op_(&o.data[o._index(i, j)], numeric.zero(types.Numeric(X)), numeric.zero(types.Numeric(Y)));
            }

            if (i < o.cols) {
                op_(&o.data[o._index(i, i)], x.data[i], numeric.zero(types.Numeric(Y)));
            }
        }
    }

    var k: usize = 0;
    while (k < y.rows) : (k += 1) {
        const i_o = if (y.direction == .forward) k else y.data[k];
        const j_o = if (y.direction == .forward) y.data[k] else k;

        const tx = if (i_o == j_o)
            x.data[i_o]
        else
            numeric.zero(types.Numeric(X));

        op_(&o.data[o._index(i_o, j_o)], tx, numeric.one(types.Numeric(Y)));
    }
}
