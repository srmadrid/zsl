const types = @import("../../../types.zig");

const int = @import("../../../int.zig");

const numeric = @import("../../../numeric.zig");
const vector = @import("../../../vector.zig");

const simd = @import("../../../simd.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) !void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    comptime var R = types.ReturnTypeFromInputs(op_, &.{ *types.Numeric(O), types.Numeric(X), Y });
    const rinfo = @typeInfo(R);
    if (rinfo == .error_union)
        R = rinfo.error_union.payload;

    if (o.len != x.len)
        return vector.Error.DimensionMismatch;

    var i: usize = 0;
    if (o.inc == 1 and x.inc == 1) {
        if (comptime op_ == numeric.mul_ or op_ == numeric.div_) {
            const sblo = simd.suggestBaseLength(types.Numeric(O));
            const sblx = simd.suggestBaseLength(types.Numeric(X));
            const sbly = simd.suggestBaseLength(Y);

            if (comptime sblo != null and sblx != null and sbly != null) {
                const bl = int.min(sblo.?, int.min(sblx.?, sbly.?));
                const len = o.len - (o.len % bl);

                while (i < len) : (i += bl) {
                    if (comptime op_ == numeric.mul_)
                        simd.mul_(o.data + i, x.data + i, y, bl)
                    else
                        simd.div_(o.data + i, x.data + i, y, bl);
                }
            }
        }

        while (i < o.len) : (i += 1) {
            if (comptime rinfo != .error_union)
                op_(&o.data[i], x.data[i], y)
            else
                try op_(&o.data[i], x.data[i], y);
        }
    } else {
        var io: isize = if (o.inc < 0) (-numeric.cast(isize, o.len) + 1) * o.inc else 0;
        var ix: isize = if (x.inc < 0) (-numeric.cast(isize, x.len) + 1) * x.inc else 0;
        while (i < o.len) : (i += 1) {
            if (comptime rinfo != .error_union)
                op_(&o.data[numeric.cast(usize, io)], x.data[numeric.cast(usize, ix)], y)
            else
                try op_(&o.data[numeric.cast(usize, io)], x.data[numeric.cast(usize, ix)], y);

            io += o.inc;
            ix += x.inc;
        }
    }
}
