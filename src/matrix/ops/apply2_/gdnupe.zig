const std = @import("std");

const types = @import("../../../types.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O = types.Child(@TypeOf(o));
    const Y = @TypeOf(y);

    o.setAll(numeric.zero(types.Numeric(O)));

    var k: usize = 0;
    while (k < y.rows) : (k += 1) {
        const i_o = if (y.direction == .forward) k else y.data[k];
        const j_o = if (y.direction == .forward) y.data[k] else k;

        op_(&o.data[o._index(i_o, j_o)], x, numeric.one(types.Numeric(Y)));
    }
}
