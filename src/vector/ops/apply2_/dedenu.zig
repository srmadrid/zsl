const types = @import("../../../types.zig");

const int = @import("../../../int.zig");

const numeric = @import("../../../numeric.zig");
const vector = @import("../../../vector.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) !void {
    if (o.len != x.len)
        return vector.Error.DimensionMismatch;

    var i: usize = 0;
    if (o.inc == 1 and x.inc == 1) {
        while (i < o.len) : (i += 1) {
            op_(&o.data[i], x.data[i], y);
        }
    } else {
        var io: isize = if (o.inc < 0) (-numeric.cast(isize, o.len) + 1) * o.inc else 0;
        var ix: isize = if (x.inc < 0) (-numeric.cast(isize, x.len) + 1) * x.inc else 0;
        while (i < o.len) : (i += 1) {
            op_(&o.data[numeric.cast(usize, io)], x.data[numeric.cast(usize, ix)], y);

            io += o.inc;
            ix += x.inc;
        }
    }
}
