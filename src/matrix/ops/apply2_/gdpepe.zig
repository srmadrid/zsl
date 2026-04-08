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
        }
    } else {
        var i: usize = 0;
        while (i < o.rows) : (i += 1) {
            var j: usize = 0;
            while (j < o.cols) : (j += 1) {
                op_(&o.data[o._index(i, j)], numeric.zero(types.Numeric(X)), numeric.zero(types.Numeric(Y)));
            }
        }
    }

    var k: usize = 0;
    while (k < x.rows) : (k += 1) {
        const i_o = if (x.direction == .forward) k else x.data[k];
        const j_o = if (x.direction == .forward) x.data[k] else k;

        const ty = if (if (y.direction == .forward) (y.data[i_o] == j_o) else (y.data[j_o] == i_o)) numeric.one(types.Numeric(Y)) else numeric.zero(types.Numeric(Y));

        op_(&o.data[o._index(i_o, j_o)], numeric.one(types.Numeric(X)), ty);
    }

    var p: usize = 0;
    while (p < y.rows) : (p += 1) {
        const i_o = if (y.direction == .forward) p else y.data[p];
        const j_o = if (y.direction == .forward) y.data[p] else p;

        if (if (x.direction == .forward) (x.data[i_o] != j_o) else (x.data[j_o] != i_o)) {
            op_(&o.data[o._index(i_o, j_o)], numeric.zero(types.Numeric(X)), numeric.one(types.Numeric(Y)));
        }
    }
}
