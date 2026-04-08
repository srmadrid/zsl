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
            if (comptime types.uploOf(Y) == .upper) {
                var i: usize = 0;
                while (i < j) : (i += 1) {
                    op_(&o.data[o._index(i, j)], numeric.zero(types.Numeric(X)), y.data[y._index(i, j)]);
                }

                op_(&o.data[o._index(j, j)], numeric.zero(types.Numeric(X)), y.data[y._index(j, j)]);

                i = j + 1;
                while (i < o.rows) : (i += 1) {
                    op_(&o.data[o._index(i, j)], numeric.zero(types.Numeric(X)), y.data[y._index(j, i)]);
                }
            } else {
                var i: usize = 0;
                while (i < j) : (i += 1) {
                    op_(&o.data[o._index(i, j)], numeric.zero(types.Numeric(X)), y.data[y._index(j, i)]);
                }

                op_(&o.data[o._index(j, j)], numeric.zero(types.Numeric(X)), y.data[y._index(j, j)]);

                i = j + 1;
                while (i < o.rows) : (i += 1) {
                    op_(&o.data[o._index(i, j)], numeric.zero(types.Numeric(X)), y.data[y._index(i, j)]);
                }
            }
        }
    } else {
        var i: usize = 0;
        while (i < o.rows) : (i += 1) {
            if (comptime types.uploOf(Y) == .lower) {
                var j: usize = 0;
                while (j < i) : (j += 1) {
                    op_(&o.data[o._index(i, j)], numeric.zero(types.Numeric(X)), y.data[y._index(i, j)]);
                }

                op_(&o.data[o._index(i, i)], numeric.zero(types.Numeric(X)), y.data[y._index(i, i)]);

                j = i + 1;
                while (j < o.cols) : (j += 1) {
                    op_(&o.data[o._index(i, j)], numeric.zero(types.Numeric(X)), y.data[y._index(j, i)]);
                }
            } else {
                var j: usize = 0;
                while (j < i) : (j += 1) {
                    op_(&o.data[o._index(i, j)], numeric.zero(types.Numeric(X)), y.data[y._index(j, i)]);
                }

                op_(&o.data[o._index(i, i)], numeric.zero(types.Numeric(X)), y.data[y._index(i, i)]);

                j = i + 1;
                while (j < o.cols) : (j += 1) {
                    op_(&o.data[o._index(i, j)], numeric.zero(types.Numeric(X)), y.data[y._index(i, j)]);
                }
            }
        }
    }

    var k: usize = 0;
    while (k < x.rows) : (k += 1) {
        const i_o = if (x.direction == .forward) k else x.data[k];
        const j_o = if (x.direction == .forward) x.data[k] else k;

        const ty = if (i_o == j_o)
            y.data[y._index(i_o, i_o)]
        else if (i_o < j_o)
            (if (comptime types.uploOf(Y) == .upper)
                y.data[y._index(i_o, j_o)]
            else
                y.data[y._index(j_o, i_o)])
        else
            (if (comptime types.uploOf(Y) == .lower)
                y.data[y._index(i_o, j_o)]
            else
                y.data[y._index(j_o, i_o)]);

        op_(&o.data[o._index(i_o, j_o)], numeric.one(types.Numeric(X)), ty);
    }
}
