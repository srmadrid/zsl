const std = @import("std");

const types = @import("../../../types.zig");
const int = @import("../../../int.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");
const utils = @import("utils.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);

    o.setAll(numeric.zero(types.Numeric(O)));

    var outer: usize = 0;
    const limit = if (comptime types.layoutOf(X) == .col_major) x.cols else x.rows;

    while (outer < limit) : (outer += 1) {
        var px = x.ptr[outer];
        while (px < x.ptr[outer + 1]) : (px += 1) {
            const i_o = if (comptime types.layoutOf(X) == .col_major) x.idx[px] else outer;
            const j_o = if (comptime types.layoutOf(X) == .col_major) outer else x.idx[px];

            op_(&o.data[o._index(i_o, j_o)], x.data[px], y);

            if (comptime types.isSymmetricMatrix(X) or types.isHermitianMatrix(X)) {
                if (i_o != j_o) {
                    const mirror_x = if (comptime types.isHermitianMatrix(X)) numeric.conj(x.data[px]) else x.data[px];
                    op_(&o.data[o._index(j_o, i_o)], mirror_x, y);
                }
            }
        }
    }

    if (comptime types.diagOf(X) == .unit) {
        var idx: usize = 0;
        while (idx < int.min(o.rows, o.cols)) : (idx += 1) {
            if (utils.searchSparse(x, idx, idx) == null) {
                op_(&o.data[o._index(idx, idx)], numeric.one(types.Numeric(X)), y);
            }
        }
    }
}
