const std = @import("std");

const types = @import("../../../types.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);

    o.setAll(numeric.zero(types.Numeric(O)));

    if (comptime types.layoutOf(X) == .col_major) {
        var j: usize = 0;
        while (j < x.cols) : (j += 1) {
            var p: usize = x.ptr[j];
            while (p < x.ptr[j + 1]) : (p += 1) {
                if (comptime types.uploOf(O) == types.uploOf(X))
                    op_(&o.data[o._index(x.idx[p], j)], x.data[p], y)
                else
                    op_(&o.data[o._index(j, x.idx[p])], x.data[p], y);
            }
        }
    } else {
        var i: usize = 0;
        while (i < x.rows) : (i += 1) {
            var p: usize = x.ptr[i];
            while (p < x.ptr[i + 1]) : (p += 1) {
                if (comptime types.uploOf(O) == types.uploOf(X))
                    op_(&o.data[o._index(i, x.idx[p])], x.data[p], y)
                else
                    op_(&o.data[o._index(x.idx[p], i)], x.data[p], y);
            }
        }
    }
}
