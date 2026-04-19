const std = @import("std");

const meta = @import("../../../meta.zig");
const int = @import("../../../int.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");
const utils = @import("utils.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = meta.Child(@TypeOf(o));
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    o.setAll(numeric.zero(meta.Numeric(O)));

    var outer: usize = 0;
    const limit = if (comptime meta.layoutOf(X) == .col_major) x.cols else x.rows;

    while (outer < limit) : (outer += 1) {
        var px = x.ptr[outer];
        while (px < x.ptr[outer + 1]) : (px += 1) {
            const i_o = if (comptime meta.layoutOf(X) == .col_major) x.idx[px] else outer;
            const j_o = if (comptime meta.layoutOf(X) == .col_major) outer else x.idx[px];

            const ty = if (i_o == j_o) y.data[i_o] else numeric.zero(meta.Numeric(Y));

            op_(&o.data[o._index(i_o, j_o)], x.data[px], ty);

            if (comptime meta.isSymmetricMatrix(X) or meta.isHermitianMatrix(X)) {
                if (i_o != j_o) {
                    const mirror_x = if (comptime meta.isHermitianMatrix(X)) numeric.conj(x.data[px]) else x.data[px];

                    op_(&o.data[o._index(j_o, i_o)], mirror_x, numeric.zero(meta.Numeric(Y)));
                }
            }
        }
    }

    var idx: usize = 0;
    while (idx < int.min(o.rows, o.cols)) : (idx += 1) {
        if (utils.searchSparse(x, idx, idx) == null) {
            const tx = if (comptime meta.diagOf(X) == .unit)
                numeric.one(meta.Numeric(X))
            else
                numeric.zero(meta.Numeric(X));

            op_(&o.data[o._index(idx, idx)], tx, y.data[idx]);
        }
    }
}
