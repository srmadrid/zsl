const int = @import("../../../int.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    var i: usize = 0;
    while (i < int.min(o.rows, o.cols)) : (i += 1) {
        op_(&o.data[i], x.data[i], y.data[i]);
    }
}
