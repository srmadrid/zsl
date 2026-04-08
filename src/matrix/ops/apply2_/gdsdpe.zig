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
            if (comptime types.uploOf(X) == .upper) {
                var i: usize = 0;
                while (i < j) : (i += 1) {
                    op_(&o.data[o._index(i, j)], x.data[x._index(i, j)], numeric.zero(types.Numeric(Y)));
                }

                op_(&o.data[o._index(j, j)], x.data[x._index(j, j)], numeric.zero(types.Numeric(Y)));

                i = j + 1;
                while (i < o.rows) : (i += 1) {
                    op_(&o.data[o._index(i, j)], x.data[x._index(j, i)], numeric.zero(types.Numeric(Y)));
                }
            } else {
                var i: usize = 0;
                while (i < j) : (i += 1) {
                    op_(&o.data[o._index(i, j)], x.data[x._index(j, i)], numeric.zero(types.Numeric(Y)));
                }

                op_(&o.data[o._index(j, j)], x.data[x._index(j, j)], numeric.zero(types.Numeric(Y)));

                i = j + 1;
                while (i < o.rows) : (i += 1) {
                    op_(&o.data[o._index(i, j)], x.data[x._index(i, j)], numeric.zero(types.Numeric(Y)));
                }
            }
        }
    } else {
        var i: usize = 0;
        while (i < o.rows) : (i += 1) {
            if (comptime types.uploOf(X) == .lower) {
                var j: usize = 0;
                while (j < i) : (j += 1) {
                    op_(&o.data[o._index(i, j)], x.data[x._index(i, j)], numeric.zero(types.Numeric(Y)));
                }

                op_(&o.data[o._index(i, i)], x.data[x._index(i, i)], numeric.zero(types.Numeric(Y)));

                j = i + 1;
                while (j < o.cols) : (j += 1) {
                    op_(&o.data[o._index(i, j)], x.data[x._index(j, i)], numeric.zero(types.Numeric(Y)));
                }
            } else {
                var j: usize = 0;
                while (j < i) : (j += 1) {
                    op_(&o.data[o._index(i, j)], x.data[x._index(j, i)], numeric.zero(types.Numeric(Y)));
                }

                op_(&o.data[o._index(i, i)], x.data[x._index(i, i)], numeric.zero(types.Numeric(Y)));

                j = i + 1;
                while (j < o.cols) : (j += 1) {
                    op_(&o.data[o._index(i, j)], x.data[x._index(i, j)], numeric.zero(types.Numeric(Y)));
                }
            }
        }
    }

    var k: usize = 0;
    while (k < y.rows) : (k += 1) {
        const i_o = if (y.direction == .forward) k else y.data[k];
        const j_o = if (y.direction == .forward) y.data[k] else k;

        const tx = if (i_o == j_o)
            x.data[x._index(i_o, i_o)]
        else if (i_o < j_o)
            (if (comptime types.uploOf(X) == .upper)
                x.data[x._index(i_o, j_o)]
            else
                x.data[x._index(j_o, i_o)])
        else
            (if (comptime types.uploOf(X) == .lower)
                x.data[x._index(i_o, j_o)]
            else
                x.data[x._index(j_o, i_o)]);

        op_(&o.data[o._index(i_o, j_o)], tx, numeric.one(types.Numeric(Y)));
    }
}
