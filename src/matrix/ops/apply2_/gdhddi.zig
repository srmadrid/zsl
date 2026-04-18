const types = @import("../../../types.zig");

const numeric = @import("../../../numeric.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);

    if (comptime types.layoutOf(O) == .col_major) {
        var j: usize = 0;
        while (j < o.cols) : (j += 1) {
            var i: usize = 0;
            while (i < j) : (i += 1) {
                const tx = if (comptime types.uploOf(X) == .upper) x.data[x._index(i, j)] else numeric.conj(x.data[x._index(j, i)]);
                numeric.set(&o.data[o._index(i, j)], tx);
            }

            op_(&o.data[o._index(j, j)], x.data[x._index(j, j)], y.data[j]);

            i = j + 1;
            while (i < o.rows) : (i += 1) {
                const tx = if (comptime types.uploOf(X) == .lower) x.data[x._index(i, j)] else numeric.conj(x.data[x._index(j, i)]);
                numeric.set(&o.data[o._index(i, j)], tx);
            }
        }
    } else {
        var i: usize = 0;
        while (i < o.rows) : (i += 1) {
            var j: usize = 0;
            while (j < i) : (j += 1) {
                const tx = if (comptime types.uploOf(X) == .lower) x.data[x._index(i, j)] else numeric.conj(x.data[x._index(j, i)]);
                numeric.set(&o.data[o._index(i, j)], tx);
            }

            op_(&o.data[o._index(i, i)], x.data[x._index(i, i)], y.data[i]);

            j = i + 1;
            while (j < o.cols) : (j += 1) {
                const tx = if (comptime types.uploOf(X) == .upper) x.data[x._index(i, j)] else numeric.conj(x.data[x._index(j, i)]);
                numeric.set(&o.data[o._index(i, j)], tx);
            }
        }
    }
}
