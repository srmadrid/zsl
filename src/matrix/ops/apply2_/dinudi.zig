const int = @import("../../../int.zig");

const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) !void {
    if (o.rows != y.rows or o.cols != y.cols)
        return matrix.Error.DimensionMismatch;

    var i: usize = 0;
    while (i < int.min(o.rows, o.cols)) : (i += 1) {
        op_(&o.data[i], x, y.data[i]);
    }
}
