const types = @import("../../../types.zig");

const numeric = @import("../../../numeric.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O = types.Child(@TypeOf(o));
    const X = @TypeOf(x);
    const Y = @TypeOf(y);

    if (comptime types.layoutOf(O) == .col_major) {
        var j: usize = 0;
        while (j < o.cols) : (j += 1) {
            if (comptime types.uploOf(X) == .upper) {
                var i: usize = 0;
                while (i < j) : (i += 1) {
                    numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                }

                const tx = if (comptime types.diagOf(X) == .unit) numeric.one(types.Numeric(X)) else x.data[x._index(j, j)];
                numeric.set(&o.data[o._index(j, j)], tx);

                i = j + 1;
                while (i < o.rows) : (i += 1) {
                    o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                }
            } else {
                var i: usize = 0;
                while (i < j) : (i += 1) {
                    o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                }

                const tx = if (comptime types.diagOf(X) == .unit) numeric.one(types.Numeric(X)) else x.data[x._index(j, j)];
                numeric.set(&o.data[o._index(j, j)], tx);

                i = j + 1;
                while (i < o.rows) : (i += 1) {
                    numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                }
            }
        }
    } else {
        var i: usize = 0;
        while (i < o.rows) : (i += 1) {
            if (comptime types.uploOf(X) == .lower) {
                var j: usize = 0;
                while (j < i) : (j += 1) {
                    numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                }

                const tx = if (comptime types.diagOf(X) == .unit) numeric.one(types.Numeric(X)) else x.data[x._index(i, i)];
                numeric.set(&o.data[o._index(i, i)], tx);

                j = i + 1;
                while (j < o.cols) : (j += 1) {
                    o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                }
            } else {
                var j: usize = 0;
                while (j < i) : (j += 1) {
                    o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                }

                const tx = if (comptime types.diagOf(X) == .unit) numeric.one(types.Numeric(X)) else x.data[x._index(i, i)];
                numeric.set(&o.data[o._index(i, i)], tx);

                j = i + 1;
                while (j < o.cols) : (j += 1) {
                    numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                }
            }
        }
    }

    var k: usize = 0;
    while (k < y.rows) : (k += 1) {
        const i = if (y.direction == .forward) k else y.data[k];
        const j = if (y.direction == .forward) y.data[k] else k;

        const tx = if (i == j)
            (if (comptime types.diagOf(X) == .unit) numeric.one(types.Numeric(X)) else x.data[x._index(i, i)])
        else if (i < j)
            (if (comptime types.uploOf(X) == .upper) x.data[x._index(i, j)] else numeric.zero(types.Numeric(X)))
        else
            (if (comptime types.uploOf(X) == .lower) x.data[x._index(i, j)] else numeric.zero(types.Numeric(X)));

        op_(&o.data[o._index(i, j)], tx, numeric.one(types.Numeric(Y)));
    }
}
