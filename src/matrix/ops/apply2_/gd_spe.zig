const std = @import("std");

const types = @import("../../../types.zig");
const int = @import("../../../int.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");
const utils = @import("utils.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O = types.Child(@TypeOf(o));
    const X = @TypeOf(x);
    const Y = @TypeOf(y);

    o.setAll(numeric.zero(types.Numeric(O)));

    var outer: usize = 0;
    const limit = if (comptime types.layoutOf(X) == .col_major) x.cols else x.rows;

    while (outer < limit) : (outer += 1) {
        var px = x.ptr[outer];
        while (px < x.ptr[outer + 1]) : (px += 1) {
            const i_o = if (comptime types.layoutOf(X) == .col_major) x.idx[px] else outer;
            const j_o = if (comptime types.layoutOf(X) == .col_major) outer else x.idx[px];

            const ty = if (y.direction == .forward)
                (if (y.data[i_o] == j_o) numeric.one(types.Numeric(Y)) else numeric.zero(types.Numeric(Y)))
            else
                (if (y.data[j_o] == i_o) numeric.one(types.Numeric(Y)) else numeric.zero(types.Numeric(Y)));

            op_(&o.data[o._index(i_o, j_o)], x.data[px], ty);

            if (comptime types.isSymmetricMatrix(X) or types.isHermitianMatrix(X)) {
                if (i_o != j_o) {
                    const mirror_x = if (comptime types.isHermitianMatrix(X)) numeric.conj(x.data[px]) else x.data[px];

                    const mirror_y = if (y.direction == .forward)
                        (if (y.data[j_o] == i_o) numeric.one(types.Numeric(Y)) else numeric.zero(types.Numeric(Y)))
                    else
                        (if (y.data[i_o] == j_o) numeric.one(types.Numeric(Y)) else numeric.zero(types.Numeric(Y)));

                    op_(&o.data[o._index(j_o, i_o)], mirror_x, mirror_y);
                }
            }
        }
    }

    var k: usize = 0;
    while (k < y.rows) : (k += 1) {
        const i_o = if (y.direction == .forward) k else y.data[k];
        const j_o = if (y.direction == .forward) y.data[k] else k;

        if (utils.searchSparse(x, i_o, j_o) == null and
            !((comptime types.isSymmetricMatrix(X) or types.isHermitianMatrix(X)) and (i_o != j_o) and utils.searchSparse(x, j_o, i_o) != null))
        {
            const tx = if (i_o == j_o and comptime types.diagOf(X) == .unit)
                numeric.one(types.Numeric(X))
            else
                numeric.zero(types.Numeric(X));

            op_(&o.data[o._index(i_o, j_o)], tx, numeric.one(types.Numeric(Y)));
        }
    }

    if (comptime types.diagOf(X) == .unit) {
        var idx: usize = 0;
        while (idx < int.min(o.rows, o.cols)) : (idx += 1) {
            if (utils.searchSparse(x, idx, idx) == null) {
                if (y.data[idx] != idx) {
                    op_(&o.data[o._index(idx, idx)], numeric.one(types.Numeric(X)), numeric.zero(types.Numeric(Y)));
                }
            }
        }
    }
}
