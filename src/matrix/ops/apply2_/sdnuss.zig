const std = @import("std");

const meta = @import("../../../meta.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = meta.Child(@TypeOf(o));
    const Y: type = @TypeOf(y);

    o.setAll(numeric.zero(meta.Numeric(O)));

    if (comptime meta.layoutOf(Y) == .col_major) {
        var j: usize = 0;
        while (j < y.cols) : (j += 1) {
            var p: usize = y.ptr[j];
            while (p < y.ptr[j + 1]) : (p += 1) {
                if (comptime meta.uploOf(O) == meta.uploOf(Y))
                    op_(&o.data[o._index(y.idx[p], j)], x, y.data[p])
                else
                    op_(&o.data[o._index(j, y.idx[p])], x, y.data[p]);
            }
        }
    } else {
        var i: usize = 0;
        while (i < y.rows) : (i += 1) {
            var p: usize = y.ptr[i];
            while (p < y.ptr[i + 1]) : (p += 1) {
                if (comptime meta.uploOf(O) == meta.uploOf(Y))
                    op_(&o.data[o._index(i, y.idx[p])], x, y.data[p])
                else
                    op_(&o.data[o._index(y.idx[p], i)], x, y.data[p]);
            }
        }
    }
}
