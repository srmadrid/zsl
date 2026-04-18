const types = @import("../../../types.zig");

const int = @import("../../../int.zig");

const numeric = @import("../../../numeric.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);

    if (comptime types.layoutOf(O) == .col_major) {
        var j: usize = 0;
        while (j < o.cols) : (j += 1) {
            if (comptime types.uploOf(O) == .upper) {
                var i: usize = 0;
                while (i < int.min(j, o.rows)) : (i += 1) {
                    op_(&o.data[o._index(i, j)], x.data[x._index(i, j)], y);
                }

                if (j < o.rows) {
                    if (comptime types.diagOf(X) == .unit) {
                        if (comptime op_ == numeric.mul_)
                            numeric.set(&o.data[o._index(j, j)], y)
                        else
                            op_(&o.data[o._index(j, j)], numeric.one(types.Numeric(X)), y);
                    } else {
                        op_(&o.data[o._index(j, j)], x.data[x._index(j, j)], y);
                    }
                }
            } else {
                if (j < o.rows) {
                    if (comptime types.diagOf(X) == .unit) {
                        if (comptime op_ == numeric.mul_)
                            numeric.set(&o.data[o._index(j, j)], y)
                        else
                            op_(&o.data[o._index(j, j)], numeric.one(types.Numeric(X)), y);
                    } else {
                        op_(&o.data[o._index(j, j)], x.data[x._index(j, j)], y);
                    }
                }

                var i: usize = int.min(j + 1, o.rows);
                while (i < o.rows) : (i += 1) {
                    op_(&o.data[o._index(i, j)], x.data[x._index(i, j)], y);
                }
            }
        }
    } else {
        var i: usize = 0;
        while (i < o.rows) : (i += 1) {
            if (comptime types.uploOf(O) == .lower) {
                var j: usize = 0;
                while (j < int.min(i, o.cols)) : (j += 1) {
                    op_(&o.data[o._index(i, j)], x.data[x._index(i, j)], y);
                }

                if (i < o.cols) {
                    if (comptime types.diagOf(X) == .unit) {
                        if (comptime op_ == numeric.mul_)
                            numeric.set(&o.data[o._index(i, i)], y)
                        else
                            op_(&o.data[o._index(i, i)], numeric.one(types.Numeric(X)), y);
                    } else {
                        op_(&o.data[o._index(i, i)], x.data[x._index(i, i)], y);
                    }
                }
            } else {
                if (i < o.cols) {
                    if (comptime types.diagOf(X) == .unit) {
                        if (comptime op_ == numeric.mul_)
                            numeric.set(&o.data[o._index(i, i)], y)
                        else
                            op_(&o.data[o._index(i, i)], numeric.one(types.Numeric(X)), y);
                    } else {
                        op_(&o.data[o._index(i, i)], x.data[x._index(i, i)], y);
                    }
                }

                var j: usize = int.min(i + 1, o.cols);
                while (j < o.cols) : (j += 1) {
                    op_(&o.data[o._index(i, j)], x.data[x._index(i, j)], y);
                }
            }
        }
    }
}
