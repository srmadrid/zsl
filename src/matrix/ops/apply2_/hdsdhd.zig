const std = @import("std");

const types = @import("../../../types.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) !void {
    const O: type = types.Child(@TypeOf(o));

    if (o.size != x.size or o.size != y.size)
        return matrix.Error.DimensionMismatch;

    switch (comptime types.layoutOf(O)) {
        .col_major => return loopColMajor(o, x, y, op_),
        .row_major => return loopRowMajor(o, x, y, op_),
    }
}

inline fn loopColMajor(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    var j: usize = 0;
    while (j < o.size) : (j += 1) {
        if (comptime types.uploOf(O) == .upper) {
            var i: usize = 0;
            while (i < j) : (i += 1) {
                const tx = if (comptime types.uploOf(X) == .upper) x.data[x._index(i, j)] else x.data[x._index(j, i)];
                const ty = if (comptime types.uploOf(Y) == .upper) y.data[y._index(i, j)] else numeric.conj(y.data[y._index(j, i)]);
                op_(&o.data[o._index(i, j)], tx, ty);
            }

            op_(&o.data[o._index(j, j)], x.data[x._index(j, j)], y.data[y._index(j, j)]);
        } else {
            op_(&o.data[o._index(j, j)], x.data[x._index(j, j)], y.data[y._index(j, j)]);

            var i: usize = j + 1;
            while (i < o.size) : (i += 1) {
                const tx = if (comptime types.uploOf(X) == .lower) x.data[x._index(i, j)] else x.data[x._index(j, i)];
                const ty = if (comptime types.uploOf(Y) == .lower) y.data[y._index(i, j)] else numeric.conj(y.data[y._index(j, i)]);
                op_(&o.data[o._index(i, j)], tx, ty);
            }
        }
    }
}

inline fn loopRowMajor(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    var i: usize = 0;
    while (i < o.size) : (i += 1) {
        if (comptime types.uploOf(O) == .lower) {
            var j: usize = 0;
            while (j < i) : (j += 1) {
                const tx = if (comptime types.uploOf(X) == .lower) x.data[x._index(i, j)] else x.data[x._index(j, i)];
                const ty = if (comptime types.uploOf(Y) == .lower) y.data[y._index(i, j)] else numeric.conj(y.data[y._index(j, i)]);
                op_(&o.data[o._index(i, j)], tx, ty);
            }

            op_(&o.data[o._index(i, i)], x.data[x._index(i, i)], y.data[y._index(i, i)]);
        } else {
            op_(&o.data[o._index(i, i)], x.data[x._index(i, i)], y.data[y._index(i, i)]);

            var j: usize = i + 1;
            while (j < o.size) : (j += 1) {
                const tx = if (comptime types.uploOf(X) == .upper) x.data[x._index(i, j)] else x.data[x._index(j, i)];
                const ty = if (comptime types.uploOf(Y) == .upper) y.data[y._index(i, j)] else numeric.conj(y.data[y._index(j, i)]);
                op_(&o.data[o._index(i, j)], tx, ty);
            }
        }
    }
}
