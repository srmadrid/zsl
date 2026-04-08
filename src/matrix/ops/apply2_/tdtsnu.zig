const std = @import("std");

const types = @import("../../../types.zig");
const int = @import("../../../int.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);

    if (comptime types.layoutOf(O) == .col_major) {
        var j: usize = 0;
        while (j < o.cols) : (j += 1) {
            if (comptime types.uploOf(O) == .upper) {
                var i: usize = 0;
                while (i < int.min(j + 1, o.rows)) : (i += 1) {
                    o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                }
            } else {
                if (j < o.rows) {
                    var i: usize = j;
                    while (i < o.rows) : (i += 1) {
                        o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                    }
                }
            }
        }
    } else {
        var i: usize = 0;
        while (i < o.rows) : (i += 1) {
            if (comptime types.uploOf(O) == .lower) {
                var j: usize = 0;
                while (j < int.min(i + 1, o.cols)) : (j += 1) {
                    o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                }
            } else {
                if (i < o.cols) {
                    var j: usize = i;
                    while (j < o.cols) : (j += 1) {
                        o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                    }
                }
            }
        }
    }

    if (comptime types.diagOf(X) == .unit) {
        var idx: usize = 0;
        while (idx < int.min(o.rows, o.cols)) : (idx += 1) {
            if (comptime op_ == numeric.mul_)
                numeric.set(&o.data[o._index(idx, idx)], y)
            else {
                op_(&o.data[o._index(idx, idx)], numeric.one(types.Numeric(X)), y);
            }
        }
    }

    if (comptime types.layoutOf(X) == .col_major) {
        var j: usize = 0;
        while (j < x.cols) : (j += 1) {
            var p: usize = x.ptr[j];
            while (p < x.ptr[j + 1]) : (p += 1) {
                op_(&o.data[o._index(x.idx[p], j)], x.data[p], y);
            }
        }
    } else {
        var i: usize = 0;
        while (i < x.rows) : (i += 1) {
            var p: usize = x.ptr[i];
            while (p < x.ptr[i + 1]) : (p += 1) {
                op_(&o.data[o._index(i, x.idx[p])], x.data[p], y);
            }
        }
    }
}
