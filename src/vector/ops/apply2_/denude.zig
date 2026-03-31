const types = @import("../../../types.zig");

const int = @import("../../../int.zig");

const numeric = @import("../../../numeric.zig");
const vector = @import("../../../vector.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) !void {
    if (o.len != y.len)
        return vector.Error.DimensionMismatch;

    var i: usize = 0;
    if (o.inc == 1 and y.inc == 1) {
        while (i < o.len) : (i += 1) {
            op_(&o.data[i], x, y.data[i]);
        }
    } else {
        var io: isize = if (o.inc < 0) (-numeric.cast(isize, o.len) + 1) * o.inc else 0;
        var iy: isize = if (y.inc < 0) (-numeric.cast(isize, y.len) + 1) * y.inc else 0;
        while (i < o.len) : (i += 1) {
            op_(&o.data[numeric.cast(usize, io)], x, y.data[numeric.cast(usize, iy)]);

            io += o.inc;
            iy += y.inc;
        }
    }
}
