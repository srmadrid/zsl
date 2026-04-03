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
            while (i <= j) : (i += 1) {
                const ty = if (comptime types.uploOf(Y) == .upper) y.data[y._index(i, j)] else y.data[y._index(j, i)];
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(i, j)], ty)
                else
                    numeric.set(&o.data[o._index(i, j)], numeric.neg(ty));
            }
        } else {
            var i: usize = j;
            while (i < o.size) : (i += 1) {
                const ty = if (comptime types.uploOf(Y) == .lower) y.data[y._index(i, j)] else y.data[y._index(j, i)];
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(i, j)], ty)
                else
                    numeric.set(&o.data[o._index(i, j)], numeric.neg(ty));
            }
        }
    }

    if (comptime types.layoutOf(X) == .col_major) {
        j = 0;
        while (j < x.size) : (j += 1) {
            var p: usize = x.ptr[j];
            while (p < x.ptr[j + 1]) : (p += 1) {
                if (comptime types.uploOf(O) == types.uploOf(X))
                    numeric.add_(&o.data[o._index(x.idx[p], j)], x.data[p], o.data[o._index(x.idx[p], j)])
                else
                    numeric.add_(&o.data[o._index(j, x.idx[p])], numeric.conj(x.data[p]), o.data[o._index(j, x.idx[p])]);
            }
        }
    } else {
        var i: usize = 0;
        while (i < x.size) : (i += 1) {
            var p: usize = x.ptr[i];
            while (p < x.ptr[i + 1]) : (p += 1) {
                if (comptime types.uploOf(O) == types.uploOf(X))
                    numeric.add_(&o.data[o._index(i, x.idx[p])], x.data[p], o.data[o._index(i, x.idx[p])])
                else
                    numeric.add_(&o.data[o._index(x.idx[p], i)], numeric.conj(x.data[p]), o.data[o._index(x.idx[p], i)]);
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
            while (j <= i) : (j += 1) {
                const ty = if (comptime types.uploOf(Y) == .lower) y.data[y._index(i, j)] else y.data[y._index(j, i)];
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(i, j)], ty)
                else
                    numeric.set(&o.data[o._index(i, j)], numeric.neg(ty));
            }
        } else {
            var j: usize = i;
            while (j < o.size) : (j += 1) {
                const ty = if (comptime types.uploOf(Y) == .upper) y.data[y._index(i, j)] else y.data[y._index(j, i)];
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(i, j)], ty)
                else
                    numeric.set(&o.data[o._index(i, j)], numeric.neg(ty));
            }
        }
    }

    if (comptime types.layoutOf(X) == .col_major) {
        var j: usize = 0;
        while (j < x.size) : (j += 1) {
            var p: usize = x.ptr[j];
            while (p < x.ptr[j + 1]) : (p += 1) {
                if (comptime types.uploOf(O) == types.uploOf(X))
                    numeric.add_(&o.data[o._index(x.idx[p], j)], x.data[p], o.data[o._index(x.idx[p], j)])
                else
                    numeric.add_(&o.data[o._index(j, x.idx[p])], numeric.conj(x.data[p]), o.data[o._index(j, x.idx[p])]);
            }
        }
    } else {
        i = 0;
        while (i < x.size) : (i += 1) {
            var p: usize = x.ptr[i];
            while (p < x.ptr[i + 1]) : (p += 1) {
                if (comptime types.uploOf(O) == types.uploOf(X))
                    numeric.add_(&o.data[o._index(i, x.idx[p])], x.data[p], o.data[o._index(i, x.idx[p])])
                else
                    numeric.add_(&o.data[o._index(x.idx[p], i)], numeric.conj(x.data[p]), o.data[o._index(x.idx[p], i)]);
            }
        }
    }
}
