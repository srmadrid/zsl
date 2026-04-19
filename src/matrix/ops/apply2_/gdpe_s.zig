const std = @import("std");

const meta = @import("../../../meta.zig");
const int = @import("../../../int.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");
const utils = @import("utils.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O = meta.Child(@TypeOf(o));
    const X = @TypeOf(x);
    const Y = @TypeOf(y);

    const NumX = meta.Numeric(X);
    const NumY = meta.Numeric(Y);

    o.setAll(numeric.zero(meta.Numeric(O)));

    var outer: usize = 0;
    const limit = if (comptime meta.layoutOf(Y) == .col_major) y.cols else y.rows;

    while (outer < limit) : (outer += 1) {
        var py = y.ptr[outer];
        while (py < y.ptr[outer + 1]) : (py += 1) {
            const i_o = if (comptime meta.layoutOf(Y) == .col_major) y.idx[py] else outer;
            const j_o = if (comptime meta.layoutOf(Y) == .col_major) outer else y.idx[py];

            const tx = if (x.direction == .forward)
                (if (x.data[i_o] == j_o) numeric.one(NumX) else numeric.zero(NumX))
            else
                (if (x.data[j_o] == i_o) numeric.one(NumX) else numeric.zero(NumX));

            op_(&o.data[o._index(i_o, j_o)], tx, y.data[py]);

            if (comptime meta.isSymmetricMatrix(Y) or meta.isHermitianMatrix(Y)) {
                if (i_o != j_o) {
                    const mirror_y = if (comptime meta.isHermitianMatrix(Y)) numeric.conj(y.data[py]) else y.data[py];

                    const mirror_x = if (x.direction == .forward)
                        (if (x.data[j_o] == i_o) numeric.one(NumX) else numeric.zero(NumX))
                    else
                        (if (x.data[i_o] == j_o) numeric.one(NumX) else numeric.zero(NumX));

                    op_(&o.data[o._index(j_o, i_o)], mirror_x, mirror_y);
                }
            }
        }
    }

    var k: usize = 0;
    while (k < x.rows) : (k += 1) {
        const i_o = if (x.direction == .forward) k else x.data[k];
        const j_o = if (x.direction == .forward) x.data[k] else k;

        if (utils.searchSparse(y, i_o, j_o) == null and
            !((comptime meta.isSymmetricMatrix(Y) or meta.isHermitianMatrix(Y)) and (i_o != j_o) and utils.searchSparse(y, j_o, i_o) != null))
        {
            const ty = if (i_o == j_o and comptime meta.diagOf(Y) == .unit)
                numeric.one(NumY)
            else
                numeric.zero(NumY);

            op_(&o.data[o._index(i_o, j_o)], numeric.one(NumX), ty);
        }
    }

    if (comptime meta.diagOf(Y) == .unit) {
        var idx: usize = 0;
        while (idx < int.min(o.rows, o.cols)) : (idx += 1) {
            if (utils.searchSparse(y, idx, idx) == null) {
                if (x.data[idx] != idx) {
                    op_(&o.data[o._index(idx, idx)], numeric.zero(NumX), numeric.one(NumY));
                }
            }
        }
    }
}
