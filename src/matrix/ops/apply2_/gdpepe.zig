const types = @import("../../../types.zig");

const numeric = @import("../../../numeric.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O = types.Child(@TypeOf(o));
    const X = @TypeOf(x);
    const Y = @TypeOf(y);

    o.setAll(numeric.zero(types.Numeric(O)));

    var k: usize = 0;
    while (k < x.rows) : (k += 1) {
        const i = if (x.direction == .forward) k else x.data[k];
        const j = if (x.direction == .forward) x.data[k] else k;

        const ty = if (if (y.direction == .forward) (y.data[i] == j) else (y.data[j] == i)) numeric.one(types.Numeric(Y)) else numeric.zero(types.Numeric(Y));

        op_(&o.data[o._index(i, j)], numeric.one(types.Numeric(X)), ty);
    }

    var p: usize = 0;
    while (p < y.rows) : (p += 1) {
        const i = if (y.direction == .forward) p else y.data[p];
        const j = if (y.direction == .forward) y.data[p] else p;

        if (if (x.direction == .forward) (x.data[i] != j) else (x.data[j] != i))
            op_(&o.data[o._index(i, j)], numeric.zero(types.Numeric(X)), numeric.one(types.Numeric(Y)));
    }
}
