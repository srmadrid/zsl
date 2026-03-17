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
    if (o.inc == 1 and y.inc == 1) {
        var ix: usize = 0;
        while (i < o.len) : (i += 1) {
            if (x.idx[ix] == i) {
                if (comptime rinfo != .error_union)
                    op_(&o.data[i], x.data[ix], y.data[i])
                else
                    try op_(&o.data[i], x.data[ix], y.data[i]);

                ix += 1;
            } else {
                if (comptime rinfo != .error_union)
                    op_(&o.data[i], numeric.zero(types.Numeric(X)), y.data[i])
                else
                    try op_(&o.data[i], numeric.zero(types.Numeric(X)), y.data[i]);
            }
        }
    } else {
        var io: isize = if (o.inc < 0) (-numeric.cast(isize, o.len) + 1) * o.inc else 0;
        var ix: usize = 0;
        var iy: isize = if (y.inc < 0) (-numeric.cast(isize, y.len) + 1) * y.inc else 0;
        while (i < o.len) : (i += 1) {
            if (x.idx[ix] == i) {
                if (comptime rinfo != .error_union)
                    op_(&o.data[numeric.cast(usize, io)], x.data[ix], y.data[numeric.cast(usize, iy)])
                else
                    try op_(&o.data[numeric.cast(usize, io)], x.data[ix], y.data[numeric.cast(usize, iy)]);

                ix += 1;
            } else {
                if (comptime rinfo != .error_union)
                    op_(&o.data[numeric.cast(usize, io)], numeric.zero(types.Numeric(X)), y.data[numeric.cast(usize, iy)])
                else
                    try op_(&o.data[numeric.cast(usize, io)], numeric.zero(types.Numeric(X)), y.data[numeric.cast(usize, iy)]);
            }

            io += o.inc;
            iy += y.inc;
        }
    }
}
