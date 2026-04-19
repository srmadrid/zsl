const meta = @import("../../../meta.zig");

const numeric = @import("../../../numeric.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = meta.Child(@TypeOf(o));
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    if (comptime meta.layoutOf(O) == .col_major) {
        var j: usize = 0;
        while (j < o.cols) : (j += 1) {
            if (comptime meta.uploOf(O) == .upper) {
                var i: usize = 0;
                while (i < j) : (i += 1) {
                    const tx = if (comptime meta.uploOf(X) == .upper) x.data[x._index(i, j)] else numeric.conj(x.data[x._index(j, i)]);
                    const ty = if (comptime meta.uploOf(Y) == .upper) y.data[y._index(i, j)] else y.data[y._index(j, i)];
                    op_(&o.data[o._index(i, j)], tx, ty);
                }

                op_(&o.data[o._index(j, j)], x.data[x._index(j, j)], y.data[y._index(j, j)]);
            } else {
                op_(&o.data[o._index(j, j)], x.data[x._index(j, j)], y.data[y._index(j, j)]);

                var i: usize = j + 1;
                while (i < o.rows) : (i += 1) {
                    const tx = if (comptime meta.uploOf(X) == .lower) x.data[x._index(i, j)] else numeric.conj(x.data[x._index(j, i)]);
                    const ty = if (comptime meta.uploOf(Y) == .lower) y.data[y._index(i, j)] else y.data[y._index(j, i)];
                    op_(&o.data[o._index(i, j)], tx, ty);
                }
            }
        }
    } else {
        var i: usize = 0;
        while (i < o.rows) : (i += 1) {
            if (comptime meta.uploOf(O) == .lower) {
                var j: usize = 0;
                while (j < i) : (j += 1) {
                    const tx = if (comptime meta.uploOf(X) == .lower) x.data[x._index(i, j)] else numeric.conj(x.data[x._index(j, i)]);
                    const ty = if (comptime meta.uploOf(Y) == .lower) y.data[y._index(i, j)] else y.data[y._index(j, i)];
                    op_(&o.data[o._index(i, j)], tx, ty);
                }

                op_(&o.data[o._index(i, i)], x.data[x._index(i, i)], y.data[y._index(i, i)]);
            } else {
                op_(&o.data[o._index(i, i)], x.data[x._index(i, i)], y.data[y._index(i, i)]);

                var j: usize = i + 1;
                while (j < o.cols) : (j += 1) {
                    const tx = if (comptime meta.uploOf(X) == .upper) x.data[x._index(i, j)] else numeric.conj(x.data[x._index(j, i)]);
                    const ty = if (comptime meta.uploOf(Y) == .upper) y.data[y._index(i, j)] else y.data[y._index(j, i)];
                    op_(&o.data[o._index(i, j)], tx, ty);
                }
            }
        }
    }
}
