const meta = @import("../../../meta.zig");

const numeric = @import("../../../numeric.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    _ = op_;

    const O = meta.Child(@TypeOf(o));

    o.setAll(numeric.zero(meta.Numeric(O)));

    var k: usize = 0;
    while (k < y.rows) : (k += 1) {
        const i = if (y.direction == .forward) k else y.data[k];
        const j = if (y.direction == .forward) y.data[k] else k;

        numeric.set(&o.data[o._index(i, j)], x);
    }
}
