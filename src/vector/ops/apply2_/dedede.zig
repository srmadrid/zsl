const types = @import("../../../types.zig");

const numeric = @import("../../../numeric.zig");
const vector = @import("../../../vector.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) !void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    comptime var R = types.ReturnTypeFromInputs(op_, &.{ *types.Numeric(O), types.Numeric(X), types.Numeric(Y) });
    const rinfo = @typeInfo(R);
    if (rinfo == .error_union)
        R = rinfo.error_union.payload;

    if (o.len != x.len or o.len != y.len)
        return vector.Error.DimensionMismatch;

    var i: usize = 0;
    if (o.inc == 1 and x.inc == 1 and y.inc == 1) {
        while (i < o.len) : (i += 1) {
            if (comptime rinfo != .error_union)
                op_(&o.data[i], x.data[i], y.data[i])
            else
                try op_(&o.data[i], x.data[i], y.data[i]);
        }
    } else {
        var io: isize = if (o.inc < 0) (-numeric.cast(isize, o.len) + 1) * o.inc else 0;
        var ix: isize = if (x.inc < 0) (-numeric.cast(isize, x.len) + 1) * x.inc else 0;
        var iy: isize = if (y.inc < 0) (-numeric.cast(isize, y.len) + 1) * y.inc else 0;
        while (i < o.len) : (i += 1) {
            if (comptime rinfo != .error_union)
                op_(&o.data[numeric.cast(usize, io)], x.data[numeric.cast(usize, ix)], y.data[numeric.cast(usize, iy)])
            else
                try op_(&o.data[numeric.cast(usize, io)], x.data[numeric.cast(usize, ix)], y.data[numeric.cast(usize, iy)]);

            io += o.inc;
            ix += x.inc;
            iy += y.inc;
        }
    }
}
