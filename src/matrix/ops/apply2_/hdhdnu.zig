const meta = @import("../../../meta.zig");

const numeric = @import("../../../numeric.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = meta.Child(@TypeOf(o));
    const X: type = @TypeOf(x);

    if (comptime meta.layoutOf(O) == .col_major) {
        var j: usize = 0;
        while (j < o.cols) : (j += 1) {
            if (comptime meta.uploOf(O) == .upper) {
                var i: usize = 0;
                while (i < j) : (i += 1) {
                    const tx = if (comptime meta.uploOf(X) == .upper) x.data[x._index(i, j)] else numeric.conj(x.data[x._index(j, i)]);
                    op_(&o.data[o._index(i, j)], tx, y);
                }

                op_(&o.data[o._index(j, j)], x.data[x._index(j, j)], y);
            } else {
                op_(&o.data[o._index(j, j)], x.data[x._index(j, j)], y);

                var i: usize = j + 1;
                while (i < o.rows) : (i += 1) {
                    const tx = if (comptime meta.uploOf(X) == .lower) x.data[x._index(i, j)] else numeric.conj(x.data[x._index(j, i)]);
                    op_(&o.data[o._index(i, j)], tx, y);
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
                    op_(&o.data[o._index(i, j)], tx, y);
                }

                op_(&o.data[o._index(i, i)], x.data[x._index(i, i)], y);
            } else {
                op_(&o.data[o._index(i, i)], x.data[x._index(i, i)], y);

                var j: usize = i + 1;
                while (j < o.cols) : (j += 1) {
                    const tx = if (comptime meta.uploOf(X) == .upper) x.data[x._index(i, j)] else numeric.conj(x.data[x._index(j, i)]);
                    op_(&o.data[o._index(i, j)], tx, y);
                }
            }
        }
    }
}
