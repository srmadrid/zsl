const std = @import("std");

const types = @import("../../../types.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    if (comptime types.layoutOf(O) == .col_major) {
        var j: usize = 0;
        while (j < o.cols) : (j += 1) {
            if (comptime types.uploOf(Y) == .upper) {
                var i: usize = 0;
                while (i < j) : (i += 1) {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(i, j)], y.data[y._index(i, j)])
                    else
                        numeric.set(&o.data[o._index(i, j)], numeric.neg(y.data[y._index(i, j)]));
                }

                if (comptime types.diagOf(Y) == .unit) {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(j, j)], numeric.one(types.Numeric(O)))
                    else
                        numeric.set(&o.data[o._index(j, j)], numeric.neg(numeric.one(types.Numeric(O))));
                } else {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(j, j)], y.data[y._index(j, j)])
                    else
                        numeric.set(&o.data[o._index(j, j)], numeric.neg(y.data[y._index(j, j)]));
                }

                i = j + 1;
                while (i < o.rows) : (i += 1) {
                    o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                }
            } else {
                var i: usize = 0;
                while (i < j) : (i += 1) {
                    o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                }

                if (comptime types.diagOf(Y) == .unit) {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(j, j)], numeric.one(types.Numeric(O)))
                    else
                        numeric.set(&o.data[o._index(j, j)], numeric.neg(numeric.one(types.Numeric(O))));
                } else {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(j, j)], y.data[y._index(j, j)])
                    else
                        numeric.set(&o.data[o._index(j, j)], numeric.neg(y.data[y._index(j, j)]));
                }

                i = j + 1;
                while (i < o.rows) : (i += 1) {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(i, j)], y.data[y._index(i, j)])
                    else
                        numeric.set(&o.data[o._index(i, j)], numeric.neg(y.data[y._index(i, j)]));
                }
            }
        }
    } else {
        var i: usize = 0;
        while (i < o.rows) : (i += 1) {
            if (comptime types.uploOf(Y) == .lower) {
                var j: usize = 0;
                while (j < i) : (j += 1) {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(i, j)], y.data[y._index(i, j)])
                    else
                        numeric.set(&o.data[o._index(i, j)], numeric.neg(y.data[y._index(i, j)]));
                }

                if (comptime types.diagOf(Y) == .unit) {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(i, i)], numeric.one(types.Numeric(O)))
                    else
                        numeric.set(&o.data[o._index(i, i)], numeric.neg(numeric.one(types.Numeric(O))));
                } else {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(i, i)], y.data[y._index(i, i)])
                    else
                        numeric.set(&o.data[o._index(i, i)], numeric.neg(y.data[y._index(i, i)]));
                }

                j = i + 1;
                while (j < o.cols) : (j += 1) {
                    o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                }
            } else {
                var j: usize = 0;
                while (j < i) : (j += 1) {
                    o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                }

                if (comptime types.diagOf(Y) == .unit) {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(i, i)], numeric.one(types.Numeric(O)))
                    else
                        numeric.set(&o.data[o._index(i, i)], numeric.neg(numeric.one(types.Numeric(O))));
                } else {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(i, i)], y.data[y._index(i, i)])
                    else
                        numeric.set(&o.data[o._index(i, i)], numeric.neg(y.data[y._index(i, i)]));
                }

                j = i + 1;
                while (j < o.cols) : (j += 1) {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[o._index(i, j)], y.data[y._index(i, j)])
                    else
                        numeric.set(&o.data[o._index(i, j)], numeric.neg(y.data[y._index(i, j)]));
                }
            }
        }
    }

    if (comptime types.layoutOf(X) == .col_major) {
        var j: usize = 0;
        while (j < x.cols) : (j += 1) {
            var p: usize = x.ptr[j];
            while (p < x.ptr[j + 1]) : (p += 1) {
                const ty1 = if (x.idx[p] == j)
                    (if (comptime types.diagOf(Y) == .unit) numeric.one(types.Numeric(Y)) else y.data[y._index(j, j)])
                else if (x.idx[p] < j)
                    (if (comptime types.uploOf(Y) == .upper) y.data[y._index(x.idx[p], j)] else numeric.zero(types.Numeric(Y)))
                else
                    (if (comptime types.uploOf(Y) == .lower) y.data[y._index(x.idx[p], j)] else numeric.zero(types.Numeric(Y)));

                op_(&o.data[o._index(x.idx[p], j)], x.data[p], ty1);

                if (x.idx[p] != j) {
                    const ty2 = if (x.idx[p] == j)
                        y.data[y._index(j, j)]
                    else if (j < x.idx[p])
                        (if (comptime types.uploOf(Y) == .upper) y.data[y._index(j, x.idx[p])] else numeric.zero(types.Numeric(Y)))
                    else
                        (if (comptime types.uploOf(Y) == .lower) y.data[y._index(j, x.idx[p])] else numeric.zero(types.Numeric(Y)));

                    op_(&o.data[o._index(j, x.idx[p])], numeric.conj(x.data[p]), ty2);
                }
            }
        }
    } else {
        var i: usize = 0;
        while (i < x.rows) : (i += 1) {
            var p: usize = x.ptr[i];
            while (p < x.ptr[i + 1]) : (p += 1) {
                const ty1 = if (i == x.idx[p])
                    (if (comptime types.diagOf(Y) == .unit) numeric.one(types.Numeric(Y)) else y.data[y._index(i, i)])
                else if (i < x.idx[p])
                    (if (comptime types.uploOf(Y) == .upper) y.data[y._index(i, x.idx[p])] else numeric.zero(types.Numeric(Y)))
                else
                    (if (comptime types.uploOf(Y) == .lower) y.data[y._index(i, x.idx[p])] else numeric.zero(types.Numeric(Y)));

                op_(&o.data[o._index(i, x.idx[p])], x.data[p], ty1);

                if (i != x.idx[p]) {
                    const ty2 = if (x.idx[p] < i)
                        (if (comptime types.uploOf(Y) == .upper) y.data[y._index(x.idx[p], i)] else numeric.zero(types.Numeric(Y)))
                    else
                        (if (comptime types.uploOf(Y) == .lower) y.data[y._index(x.idx[p], i)] else numeric.zero(types.Numeric(Y)));

                    op_(&o.data[o._index(x.idx[p], i)], numeric.conj(x.data[p]), ty2);
                }
            }
        }
    }
}
