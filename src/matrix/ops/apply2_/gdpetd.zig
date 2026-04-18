const types = @import("../../../types.zig");

const numeric = @import("../../../numeric.zig");

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
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(i, j)], y.data[y._index(i, j)])
                    else
                        numeric.set(&o.data[o._index(i, j)], numeric.neg(y.data[y._index(i, j)]));
                }

                const ty = if (comptime types.diagOf(Y) == .unit) numeric.one(types.Numeric(Y)) else y.data[y._index(j, j)];
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(j, j)], ty)
                else
                    numeric.set(&o.data[o._index(j, j)], numeric.neg(ty));

                i = j + 1;
                while (i < o.rows) : (i += 1) {
                    o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                }
            } else {
                var i: usize = 0;
                while (i < j) : (i += 1) {
                    o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                }

                const ty = if (comptime types.diagOf(Y) == .unit) numeric.one(types.Numeric(Y)) else y.data[y._index(j, j)];
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(j, j)], ty)
                else
                    numeric.set(&o.data[o._index(j, j)], numeric.neg(ty));

                i = j + 1;
                while (i < o.rows) : (i += 1) {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(i, j)], y.data[y._index(i, j)])
                    else
                        numeric.set(&o.data[o._index(i, j)], numeric.neg(y.data[y._index(i, j)]));
                }
            }
        }
    } else {
        var i: usize = 0;
        while (i < o.rows) : (i += 1) {
            if (comptime types.uploOf(Y) == .lower) {
                var j: usize = 0;
                while (j < i) : (j += 1) {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(i, j)], y.data[y._index(i, j)])
                    else
                        numeric.set(&o.data[o._index(i, j)], numeric.neg(y.data[y._index(i, j)]));
                }

                const ty = if (comptime types.diagOf(Y) == .unit) numeric.one(types.Numeric(Y)) else y.data[y._index(i, i)];
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(i, i)], ty)
                else
                    numeric.set(&o.data[o._index(i, i)], numeric.neg(ty));

                j = i + 1;
                while (j < o.cols) : (j += 1) {
                    o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                }
            } else {
                var j: usize = 0;
                while (j < i) : (j += 1) {
                    o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                }

                const ty = if (comptime types.diagOf(Y) == .unit) numeric.one(types.Numeric(Y)) else y.data[y._index(i, i)];
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(i, i)], ty)
                else
                    numeric.set(&o.data[o._index(i, i)], numeric.neg(ty));

                j = i + 1;
                while (j < o.cols) : (j += 1) {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(i, j)], y.data[y._index(i, j)])
                    else
                        numeric.set(&o.data[o._index(i, j)], numeric.neg(y.data[y._index(i, j)]));
                }
            }
        }
    }

    var k: usize = 0;
    while (k < x.rows) : (k += 1) {
        const i = if (x.direction == .forward) k else x.data[k];
        const j = if (x.direction == .forward) x.data[k] else k;

        const ty = if (i == j)
            (if (comptime types.diagOf(Y) == .unit) numeric.one(types.Numeric(Y)) else y.data[y._index(i, i)])
        else if (i < j)
            (if (comptime types.uploOf(Y) == .upper) y.data[y._index(i, j)] else numeric.zero(types.Numeric(Y)))
        else
            (if (comptime types.uploOf(Y) == .lower) y.data[y._index(i, j)] else numeric.zero(types.Numeric(Y)));

        op_(&o.data[o._index(i, j)], numeric.one(types.Numeric(X)), ty);
    }
}
