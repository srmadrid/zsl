const std = @import("std");

const types = @import("../../../types.zig");
const int = @import("../../../int.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) !void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    if (o.size != x.size or o.size != y.size)
        return matrix.Error.DimensionMismatch;

    if (comptime types.layoutOf(O) == .col_major) {
        var j: usize = 0;
        while (j < o.size) : (j += 1) {
            if (comptime types.uploOf(O) == .upper) {
                var i: usize = 0;
                while (i < j) : (i += 1) {
                    const tx = if (comptime types.uploOf(X) == .upper) x.data[x._index(i, j)] else x.data[x._index(j, i)];
                    numeric.set(&o.data[o._index(i, j)], tx);
                }

                numeric.set(&o.data[o._index(j, j)], x.data[x._index(j, j)]);
            } else {
                numeric.set(&o.data[o._index(j, j)], x.data[x._index(j, j)]);

                var i: usize = j + 1;
                while (i < o.size) : (i += 1) {
                    const tx = if (comptime types.uploOf(X) == .lower) x.data[x._index(i, j)] else x.data[x._index(j, i)];
                    numeric.set(&o.data[o._index(i, j)], tx);
                }
            }
        }
    } else {
        var i: usize = 0;
        while (i < o.size) : (i += 1) {
            if (comptime types.uploOf(O) == .lower) {
                var j: usize = 0;
                while (j < i) : (j += 1) {
                    const tx = if (comptime types.uploOf(X) == .lower) x.data[x._index(i, j)] else x.data[x._index(j, i)];
                    numeric.set(&o.data[o._index(i, j)], tx);
                }

                numeric.set(&o.data[o._index(i, i)], x.data[x._index(i, i)]);
            } else {
                numeric.set(&o.data[o._index(i, i)], x.data[x._index(i, i)]);

                var j: usize = i + 1;
                while (j < o.size) : (j += 1) {
                    const tx = if (comptime types.uploOf(X) == .upper) x.data[x._index(i, j)] else x.data[x._index(j, i)];
                    numeric.set(&o.data[o._index(i, j)], tx);
                }
            }
        }
    }

    if (comptime types.layoutOf(Y) == .col_major) {
        var j: usize = 0;
        while (j < y.size) : (j += 1) {
            var p: usize = y.ptr[j];
            while (p < y.ptr[j + 1]) : (p += 1) {
                if (comptime types.uploOf(O) == types.uploOf(Y)) {
                    const tx = if (comptime types.uploOf(X) == types.uploOf(O))
                        x.data[x._index(y.idx[p], j)]
                    else
                        x.data[x._index(j, y.idx[p])];

                    op_(&o.data[o._index(y.idx[p], j)], tx, y.data[p]);
                } else {
                    const tx = if (comptime types.uploOf(X) == types.uploOf(O))
                        x.data[x._index(j, y.idx[p])]
                    else
                        x.data[x._index(y.idx[p], j)];

                    op_(&o.data[o._index(j, y.idx[p])], tx, y.data[p]);
                }
            }
        }
    } else {
        var i: usize = 0;
        while (i < y.size) : (i += 1) {
            var p: usize = y.ptr[i];
            while (p < y.ptr[i + 1]) : (p += 1) {
                if (comptime types.uploOf(O) == types.uploOf(Y)) {
                    const tx = if (comptime types.uploOf(X) == types.uploOf(O))
                        x.data[x._index(i, y.idx[p])]
                    else
                        x.data[x._index(y.idx[p], i)];

                    op_(&o.data[o._index(i, y.idx[p])], tx, y.data[p]);
                } else {
                    const tx = if (comptime types.uploOf(X) == types.uploOf(O))
                        x.data[x._index(y.idx[p], i)]
                    else
                        x.data[x._index(i, y.idx[p])];

                    op_(&o.data[o._index(y.idx[p], i)], tx, y.data[p]);
                }
            }
        }
    }
}
