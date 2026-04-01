const std = @import("std");

const types = @import("../../../types.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) !void {
    const O: type = types.Child(@TypeOf(o));

    if (y.rows != y.cols or o.size != y.rows)
        return matrix.Error.DimensionMismatch;

    switch (comptime types.layoutOf(O)) {
        .col_major => return loopColMajor(o, x, y, op_),
        .row_major => return loopRowMajor(o, x, y, op_),
    }
}

inline fn loopColMajor(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));

    var j: usize = 0;
    while (j < o.size) : (j += 1) {
        if (comptime types.uploOf(O) == .upper) {
            var i: usize = 0;
            while (i < j) : (i += 1) {
                o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
            }

            op_(&o.data[o._index(j, j)], x, y.data[j]);
        } else {
            op_(&o.data[o._index(j, j)], x, y.data[j]);

            var i: usize = j + 1;
            while (i < o.size) : (i += 1) {
                o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
            }
        }
    }
}

inline fn loopRowMajor(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));

    var i: usize = 0;
    while (i < o.size) : (i += 1) {
        if (comptime types.uploOf(O) == .lower) {
            var j: usize = 0;
            while (j < i) : (j += 1) {
                o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
            }

            op_(&o.data[o._index(i, i)], x, y.data[i]);
        } else {
            op_(&o.data[o._index(i, i)], x, y.data[i]);

            var j: usize = i + 1;
            while (j < o.size) : (j += 1) {
                o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
            }
        }
    }
}
