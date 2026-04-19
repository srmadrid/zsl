const std = @import("std");

const meta = @import("../../../meta.zig");

const numeric = @import("../../../numeric.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = meta.Child(@TypeOf(o));
    const X: type = @TypeOf(x);

    const aliased = (comptime O == X) and std.meta.eql(o.*, x);

    if (comptime meta.layoutOf(O) == .col_major) {
        var j: usize = 0;
        while (j < o.cols) : (j += 1) {
            if (comptime meta.uploOf(O) == .upper) {
                if (!aliased) {
                    var i: usize = 0;
                    while (i < j) : (i += 1) {
                        const tx = if (comptime meta.uploOf(X) == .upper) x.data[x._index(i, j)] else x.data[x._index(j, i)];
                        numeric.set(&o.data[o._index(i, j)], tx);
                    }
                }

                op_(&o.data[o._index(j, j)], x.data[x._index(j, j)], y.data[j]);
            } else {
                op_(&o.data[o._index(j, j)], x.data[x._index(j, j)], y.data[j]);

                if (!aliased) {
                    var i: usize = j + 1;
                    while (i < o.rows) : (i += 1) {
                        const tx = if (comptime meta.uploOf(X) == .lower) x.data[x._index(i, j)] else x.data[x._index(j, i)];
                        numeric.set(&o.data[o._index(i, j)], tx);
                    }
                }
            }
        }
    } else {
        var i: usize = 0;
        while (i < o.rows) : (i += 1) {
            if (comptime meta.uploOf(O) == .lower) {
                if (!aliased) {
                    var j: usize = 0;
                    while (j < i) : (j += 1) {
                        const tx = if (comptime meta.uploOf(X) == .lower) x.data[x._index(i, j)] else x.data[x._index(j, i)];
                        numeric.set(&o.data[o._index(i, j)], tx);
                    }
                }

                op_(&o.data[o._index(i, i)], x.data[x._index(i, i)], y.data[i]);
            } else {
                op_(&o.data[o._index(i, i)], x.data[x._index(i, i)], y.data[i]);

                if (!aliased) {
                    var j: usize = i + 1;
                    while (j < o.cols) : (j += 1) {
                        const tx = if (comptime meta.uploOf(X) == .upper) x.data[x._index(i, j)] else x.data[x._index(j, i)];
                        numeric.set(&o.data[o._index(i, j)], tx);
                    }
                }
            }
        }
    }
}
