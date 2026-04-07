const std = @import("std");

const types = @import("../../../types.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) !void {
    const O: type = types.Child(@TypeOf(o));
    const Y: type = @TypeOf(y);

    if (o.rows != o.cols or o.rows != y.size)
        return matrix.Error.DimensionMismatch;

    o.setAll(numeric.zero(types.Numeric(O)));

    if (comptime types.layoutOf(Y) == .col_major) {
        var j: usize = 0;
        while (j < y.size) : (j += 1) {
            var p: usize = y.ptr[j];
            while (p < y.ptr[j + 1]) : (p += 1) {
                op_(&o.data[o._index(y.idx[p], j)], x, y.data[p]);

                if (y.idx[p] != j) {
                    op_(&o.data[o._index(j, y.idx[p])], x, numeric.conj(y.data[p]));
                }
            }
        }
    } else {
        var i: usize = 0;
        while (i < y.size) : (i += 1) {
            var p: usize = y.ptr[i];
            while (p < y.ptr[i + 1]) : (p += 1) {
                op_(&o.data[o._index(i, y.idx[p])], x, y.data[p]);

                if (i != y.idx[p]) {
                    op_(&o.data[o._index(y.idx[p], i)], x, numeric.conj(y.data[p]));
                }
            }
        }
    }
}
