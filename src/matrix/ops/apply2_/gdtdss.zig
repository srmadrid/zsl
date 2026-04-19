const std = @import("std");

const meta = @import("../../../meta.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = meta.Child(@TypeOf(o));
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    if (comptime meta.layoutOf(O) == .col_major) {
        var j: usize = 0;
        while (j < o.cols) : (j += 1) {
            if (comptime meta.uploOf(X) == .upper) {
                var i: usize = 0;
                while (i < j) : (i += 1) {
                    numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                }

                if (comptime meta.diagOf(X) == .unit)
                    numeric.set(&o.data[o._index(j, j)], numeric.one(meta.Numeric(O)))
                else
                    numeric.set(&o.data[o._index(j, j)], x.data[x._index(j, j)]);

                i = j + 1;
                while (i < o.rows) : (i += 1) {
                    o.data[o._index(i, j)] = numeric.zero(meta.Numeric(O));
                }
            } else {
                var i: usize = 0;
                while (i < j) : (i += 1) {
                    o.data[o._index(i, j)] = numeric.zero(meta.Numeric(O));
                }

                if (comptime meta.diagOf(X) == .unit)
                    numeric.set(&o.data[o._index(j, j)], numeric.one(meta.Numeric(O)))
                else
                    numeric.set(&o.data[o._index(j, j)], x.data[x._index(j, j)]);

                i = j + 1;
                while (i < o.rows) : (i += 1) {
                    numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                }
            }
        }
    } else {
        var i: usize = 0;
        while (i < o.rows) : (i += 1) {
            if (comptime meta.uploOf(X) == .lower) {
                var j: usize = 0;
                while (j < i) : (j += 1) {
                    numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                }

                if (comptime meta.diagOf(X) == .unit)
                    numeric.set(&o.data[o._index(i, i)], numeric.one(meta.Numeric(O)))
                else
                    numeric.set(&o.data[o._index(i, i)], x.data[x._index(i, i)]);

                j = i + 1;
                while (j < o.cols) : (j += 1) {
                    o.data[o._index(i, j)] = numeric.zero(meta.Numeric(O));
                }
            } else {
                var j: usize = 0;
                while (j < i) : (j += 1) {
                    o.data[o._index(i, j)] = numeric.zero(meta.Numeric(O));
                }

                if (comptime meta.diagOf(X) == .unit)
                    numeric.set(&o.data[o._index(i, i)], numeric.one(meta.Numeric(O)))
                else
                    numeric.set(&o.data[o._index(i, i)], x.data[x._index(i, i)]);

                j = i + 1;
                while (j < o.cols) : (j += 1) {
                    numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                }
            }
        }
    }

    if (comptime meta.layoutOf(Y) == .col_major) {
        var j: usize = 0;
        while (j < y.cols) : (j += 1) {
            var p: usize = y.ptr[j];
            while (p < y.ptr[j + 1]) : (p += 1) {
                const tx1 = if (y.idx[p] == j)
                    (if (comptime meta.diagOf(X) == .unit) numeric.one(meta.Numeric(X)) else x.data[x._index(j, j)])
                else if (y.idx[p] < j)
                    (if (comptime meta.uploOf(X) == .upper) x.data[x._index(y.idx[p], j)] else numeric.zero(meta.Numeric(X)))
                else
                    (if (comptime meta.uploOf(X) == .lower) x.data[x._index(y.idx[p], j)] else numeric.zero(meta.Numeric(X)));

                op_(&o.data[o._index(y.idx[p], j)], tx1, y.data[p]);

                if (y.idx[p] != j) {
                    const tx2 = if (j < y.idx[p])
                        (if (comptime meta.uploOf(X) == .upper) x.data[x._index(j, y.idx[p])] else numeric.zero(meta.Numeric(X)))
                    else
                        (if (comptime meta.uploOf(X) == .lower) x.data[x._index(j, y.idx[p])] else numeric.zero(meta.Numeric(X)));

                    op_(&o.data[o._index(j, y.idx[p])], tx2, y.data[p]);
                }
            }
        }
    } else {
        var i: usize = 0;
        while (i < y.rows) : (i += 1) {
            var p: usize = y.ptr[i];
            while (p < y.ptr[i + 1]) : (p += 1) {
                const tx1 = if (i == y.idx[p])
                    (if (comptime meta.diagOf(X) == .unit) numeric.one(meta.Numeric(X)) else x.data[x._index(i, i)])
                else if (i < y.idx[p])
                    (if (comptime meta.uploOf(X) == .upper) x.data[x._index(i, y.idx[p])] else numeric.zero(meta.Numeric(X)))
                else
                    (if (comptime meta.uploOf(X) == .lower) x.data[x._index(i, y.idx[p])] else numeric.zero(meta.Numeric(X)));

                op_(&o.data[o._index(i, y.idx[p])], tx1, y.data[p]);

                if (i != y.idx[p]) {
                    const tx2 = if (i == y.idx[p])
                        (if (comptime meta.diagOf(X) == .unit) numeric.one(meta.Numeric(X)) else x.data[x._index(i, i)])
                    else if (y.idx[p] < i)
                        (if (comptime meta.uploOf(X) == .upper) x.data[x._index(y.idx[p], i)] else numeric.zero(meta.Numeric(X)))
                    else
                        (if (comptime meta.uploOf(X) == .lower) x.data[x._index(y.idx[p], i)] else numeric.zero(meta.Numeric(X)));

                    op_(&o.data[o._index(y.idx[p], i)], tx2, y.data[p]);
                }
            }
        }
    }
}
