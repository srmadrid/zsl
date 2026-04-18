const types = @import("../../../types.zig");

const numeric = @import("../../../numeric.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));
    const Y: type = @TypeOf(y);

    if (comptime types.layoutOf(O) == .col_major) {
        var j: usize = 0;
        while (j < o.cols) : (j += 1) {
            var i: usize = 0;
            while (i < j) : (i += 1) {
                const ty = if (comptime types.uploOf(Y) == .upper) y.data[y._index(i, j)] else y.data[y._index(j, i)];
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(i, j)], ty)
                else
                    numeric.set(&o.data[o._index(i, j)], numeric.neg(ty));
            }

            op_(&o.data[o._index(j, j)], x.data[j], y.data[y._index(j, j)]);

            i = j + 1;
            while (i < o.rows) : (i += 1) {
                const ty = if (comptime types.uploOf(Y) == .lower) y.data[y._index(i, j)] else y.data[y._index(j, i)];
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(i, j)], ty)
                else
                    numeric.set(&o.data[o._index(i, j)], numeric.neg(ty));
            }
        }
    } else {
        var i: usize = 0;
        while (i < o.rows) : (i += 1) {
            var j: usize = 0;
            while (j < i) : (j += 1) {
                const ty = if (comptime types.uploOf(Y) == .lower) y.data[y._index(i, j)] else y.data[y._index(j, i)];
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(i, j)], ty)
                else
                    numeric.set(&o.data[o._index(i, j)], numeric.neg(ty));
            }

            op_(&o.data[o._index(i, i)], x.data[i], y.data[y._index(i, i)]);

            j = i + 1;
            while (j < o.cols) : (j += 1) {
                const ty = if (comptime types.uploOf(Y) == .upper) y.data[y._index(i, j)] else y.data[y._index(j, i)];
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(i, j)], ty)
                else
                    numeric.set(&o.data[o._index(i, j)], numeric.neg(ty));
            }
        }
    }
}
