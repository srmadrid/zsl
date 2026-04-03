const types = @import("../../../types.zig");

const int = @import("../../../int.zig");

const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) !void {
    const O: type = types.Child(@TypeOf(o));

    if (o.rows != x.rows or o.cols != x.cols or o.rows != y.rows or o.cols != y.cols)
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
    while (j < o.cols) : (j += 1) {
        var i: usize = 0;
        while (i < int.min(j, o.rows)) : (i += 1) {
            o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
        }

        if (j < o.rows) {
            if (comptime types.diagOf(Y) == .unit) {
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(j, j)], numeric.one(types.Numeric(O)))
                else
                    numeric.set(&o.data[o._index(j, j)], numeric.neg(numeric.one(types.Numeric(O))));
            } else {
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(j, j)], y.data[j])
                else
                    numeric.set(&o.data[o._index(j, j)], numeric.neg(y.data[j]));
            }
        }

        i = int.min(j + 1, o.rows);
        while (i < o.rows) : (i += 1) {
            o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
        }
    }

    if (comptime types.layoutOf(X) == .col_major) {
        j = 0;
        while (j < x.cols) : (j += 1) {
            var p: usize = x.ptr[j];
            while (p < x.ptr[j + 1]) : (p += 1) {
                numeric.add_(&o.data[o._index(x.idx[p], j)], x.data[p], o.data[o._index(x.idx[p], j)]);
            }
        }
    } else {
        var i: usize = 0;
        while (i < x.rows) : (i += 1) {
            var p: usize = x.ptr[i];
            while (p < x.ptr[i + 1]) : (p += 1) {
                numeric.add_(&o.data[o._index(i, x.idx[p])], x.data[p], o.data[o._index(i, x.idx[p])]);
            }
        }
    }
}

inline fn loopRowMajor(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    var i: usize = 0;
    while (i < o.rows) : (i += 1) {
        var j: usize = 0;
        while (j < int.min(i, o.cols)) : (j += 1) {
            o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
        }

        if (i < o.cols) {
            if (comptime types.diagOf(Y) == .unit) {
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(i, i)], numeric.one(types.Numeric(O)))
                else
                    numeric.set(&o.data[o._index(i, i)], numeric.neg(numeric.one(types.Numeric(O))));
            } else {
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[o._index(i, i)], y.data[i])
                else
                    numeric.set(&o.data[o._index(i, i)], numeric.neg(y.data[i]));
            }
        }

        j = int.min(i + 1, o.cols);
        while (j < o.cols) : (j += 1) {
            o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
        }
    }

    if (comptime types.layoutOf(X) == .col_major) {
        var j: usize = 0;
        while (j < x.cols) : (j += 1) {
            var p: usize = x.ptr[j];
            while (p < x.ptr[j + 1]) : (p += 1) {
                numeric.add_(&o.data[o._index(x.idx[p], j)], x.data[p], o.data[o._index(x.idx[p], j)]);
            }
        }
    } else {
        i = 0;
        while (i < x.rows) : (i += 1) {
            var p: usize = x.ptr[i];
            while (p < x.ptr[i + 1]) : (p += 1) {
                numeric.add_(&o.data[o._index(i, x.idx[p])], x.data[p], o.data[o._index(i, x.idx[p])]);
            }
        }
    }
}
