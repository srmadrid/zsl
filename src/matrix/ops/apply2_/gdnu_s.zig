const std = @import("std");

const meta = @import("../../../meta.zig");
const int = @import("../../../int.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");
const utils = @import("utils.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = meta.Child(@TypeOf(o));
    const Y: type = @TypeOf(y);

    o.setAll(numeric.zero(meta.Numeric(O)));

    var outer: usize = 0;
    const limit = if (comptime meta.layoutOf(Y) == .col_major) y.cols else y.rows;

    while (outer < limit) : (outer += 1) {
        var py = y.ptr[outer];
        while (py < y.ptr[outer + 1]) : (py += 1) {
            const i_o = if (comptime meta.layoutOf(Y) == .col_major) y.idx[py] else outer;
            const j_o = if (comptime meta.layoutOf(Y) == .col_major) outer else y.idx[py];

            op_(&o.data[o._index(i_o, j_o)], x, y.data[py]);

            if (comptime meta.isSymmetricMatrix(Y) or meta.isHermitianMatrix(Y)) {
                if (i_o != j_o) {
                    const mirror_y = if (comptime meta.isHermitianMatrix(Y)) numeric.conj(y.data[py]) else y.data[py];
                    op_(&o.data[o._index(j_o, i_o)], x, mirror_y);
                }
            }
        }
    }

    if (comptime meta.diagOf(Y) == .unit) {
        var idx: usize = 0;
        while (idx < int.min(o.rows, o.cols)) : (idx += 1) {
            if (utils.searchSparse(y, idx, idx) == null) {
                op_(&o.data[o._index(idx, idx)], x, numeric.one(meta.Numeric(Y)));
            }
        }
    }
}
