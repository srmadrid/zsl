const std = @import("std");

const meta = @import("../../../meta.zig");
const int = @import("../../../int.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = meta.Child(@TypeOf(o));
    const Y: type = @TypeOf(y);

    if (comptime meta.layoutOf(O) == .col_major) {
        var j: usize = 0;
        while (j < o.cols) : (j += 1) {
            if (comptime meta.uploOf(O) == .upper) {
                var i: usize = 0;
                while (i < int.min(j + 1, o.rows)) : (i += 1) {
                    o.data[o._index(i, j)] = numeric.zero(meta.Numeric(O));
                }
            } else {
                if (j < o.rows) {
                    var i: usize = j;
                    while (i < o.rows) : (i += 1) {
                        o.data[o._index(i, j)] = numeric.zero(meta.Numeric(O));
                    }
                }
            }
        }
    } else {
        var i: usize = 0;
        while (i < o.rows) : (i += 1) {
            if (comptime meta.uploOf(O) == .lower) {
                var j: usize = 0;
                while (j < int.min(i + 1, o.cols)) : (j += 1) {
                    o.data[o._index(i, j)] = numeric.zero(meta.Numeric(O));
                }
            } else {
                if (i < o.cols) {
                    var j: usize = i;
                    while (j < o.cols) : (j += 1) {
                        o.data[o._index(i, j)] = numeric.zero(meta.Numeric(O));
                    }
                }
            }
        }
    }

    if (comptime meta.diagOf(Y) == .unit) {
        var idx: usize = 0;
        while (idx < int.min(o.rows, o.cols)) : (idx += 1) {
            numeric.set(&o.data[o._index(idx, idx)], x);
        }
    }

    if (comptime meta.layoutOf(Y) == .col_major) {
        var j: usize = 0;
        while (j < y.cols) : (j += 1) {
            var p: usize = y.ptr[j];
            while (p < y.ptr[j + 1]) : (p += 1) {
                op_(&o.data[o._index(y.idx[p], j)], x, y.data[p]);
            }
        }
    } else {
        var i: usize = 0;
        while (i < y.rows) : (i += 1) {
            var p: usize = y.ptr[i];
            while (p < y.ptr[i + 1]) : (p += 1) {
                op_(&o.data[o._index(i, y.idx[p])], x, y.data[p]);
            }
        }
    }
}
