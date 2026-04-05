const std = @import("std");

const types = @import("../../../types.zig");
const int = @import("../../../int.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) !void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    if (o.rows != x.rows or o.cols != x.cols or
        o.rows != y.rows or o.cols != y.cols)
        return matrix.Error.DimensionMismatch;

    const aliased = (comptime O == X) and std.meta.eql(o.*, x);

    if (!aliased) {
        if (comptime types.layoutOf(O) == .col_major) {
            var j: usize = 0;
            while (j < o.cols) : (j += 1) {
                if (comptime types.uploOf(O) == .upper) {
                    var i: usize = 0;
                    while (i < int.min(j, o.rows)) : (i += 1) {
                        numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                    }

                    if (j < o.rows) {
                        if (comptime types.diagOf(X) == .unit) {
                            numeric.set(&o.data[o._index(j, j)], numeric.one(types.Numeric(O)));
                        } else {
                            numeric.set(&o.data[o._index(j, j)], x.data[x._index(j, j)]);
                        }
                    }
                } else {
                    if (j < o.rows) {
                        if (comptime types.diagOf(X) == .unit) {
                            numeric.set(&o.data[o._index(j, j)], numeric.one(types.Numeric(O)));
                        } else {
                            numeric.set(&o.data[o._index(j, j)], x.data[x._index(j, j)]);
                        }
                    }

                    var i: usize = j + 1;
                    while (i < o.rows) : (i += 1) {
                        numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                    }
                }
            }
        } else {
            var i: usize = 0;
            while (i < o.rows) : (i += 1) {
                if (comptime types.uploOf(O) == .lower) {
                    var j: usize = 0;
                    while (j < int.min(i, o.cols)) : (j += 1) {
                        numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                    }

                    if (i < o.cols) {
                        if (comptime types.diagOf(X) == .unit) {
                            numeric.set(&o.data[o._index(i, i)], numeric.one(types.Numeric(O)));
                        } else {
                            numeric.set(&o.data[o._index(i, i)], x.data[x._index(i, i)]);
                        }
                    }
                } else {
                    if (i < o.cols) {
                        if (comptime types.diagOf(X) == .unit) {
                            numeric.set(&o.data[o._index(i, i)], numeric.one(types.Numeric(O)));
                        } else {
                            numeric.set(&o.data[o._index(i, i)], x.data[x._index(i, i)]);
                        }
                    }

                    var j: usize = i + 1;
                    while (j < o.cols) : (j += 1) {
                        numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                    }
                }
            }
        }
    }

    if (comptime types.diagOf(Y) == .unit) {
        var i: usize = 0;
        while (i < int.min(o.rows, o.cols)) : (i += 1) {
            if (comptime types.diagOf(X) == .unit)
                op_(&o.data[o._index(i, i)], numeric.one(types.Numeric(X)), numeric.one(types.Numeric(Y)))
            else
                op_(&o.data[o._index(i, i)], x.data[x._index(i, i)], numeric.one(types.Numeric(Y)));
        }
    }

    if (comptime types.layoutOf(Y) == .col_major) {
        var j: usize = 0;
        while (j < y.cols) : (j += 1) {
            var p: usize = y.ptr[j];
            while (p < y.ptr[j + 1]) : (p += 1) {
                const tx = if (y.idx[p] == j)
                    (if (comptime types.diagOf(X) == .unit) numeric.one(types.Numeric(X)) else x.data[x._index(j, j)])
                else
                    x.data[x._index(y.idx[p], j)];

                op_(&o.data[o._index(y.idx[p], j)], tx, y.data[p]);
            }
        }
    } else {
        var i: usize = 0;
        while (i < y.rows) : (i += 1) {
            var p: usize = y.ptr[i];
            while (p < y.ptr[i + 1]) : (p += 1) {
                const tx = if (i == y.idx[p])
                    (if (comptime types.diagOf(X) == .unit) numeric.one(types.Numeric(X)) else x.data[x._index(i, i)])
                else
                    x.data[x._index(i, y.idx[p])];

                op_(&o.data[o._index(i, y.idx[p])], tx, y.data[p]);
            }
        }
    }
}
