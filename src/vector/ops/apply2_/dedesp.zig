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
    if (o.inc == 1 and x.inc == 1) {
        var iy: usize = 0;
        while (iy < y.nnz) : (iy += 1) {
            while (i < y.idx[iy]) : (i += 1) {
                if (comptime rinfo != .error_union)
                    op_(&o.data[i], x.data[i], numeric.zero(types.Numeric(Y)))
                else
                    try op_(&o.data[i], x.data[i], numeric.zero(types.Numeric(Y)));
            }

            if (comptime rinfo != .error_union)
                op_(&o.data[i], x.data[i], y.data[iy])
            else
                try op_(&o.data[i], x.data[i], y.data[iy]);

            i += 1;
        }

        while (i < o.len) : (i += 1) {
            if (comptime rinfo != .error_union)
                op_(&o.data[i], x.data[i], numeric.zero(types.Numeric(Y)))
            else
                try op_(&o.data[i], x.data[i], numeric.zero(types.Numeric(Y)));
        }
    } else {
        var io: isize = if (o.inc < 0) (-numeric.cast(isize, o.len) + 1) * o.inc else 0;
        var ix: isize = if (x.inc < 0) (-numeric.cast(isize, x.len) + 1) * x.inc else 0;
        var iy: usize = 0;

        while (iy < y.nnz) : (iy += 1) {
            while (i < y.idx[iy]) : (i += 1) {
                if (comptime rinfo != .error_union)
                    op_(&o.data[numeric.cast(usize, io)], x.data[numeric.cast(usize, ix)], numeric.zero(types.Numeric(Y)))
                else
                    try op_(&o.data[numeric.cast(usize, io)], x.data[numeric.cast(usize, ix)], numeric.zero(types.Numeric(Y)));

                io += o.inc;
                ix += x.inc;
            }

            if (comptime rinfo != .error_union)
                op_(&o.data[numeric.cast(usize, io)], x.data[numeric.cast(usize, ix)], y.data[iy])
            else
                try op_(&o.data[numeric.cast(usize, io)], x.data[numeric.cast(usize, ix)], y.data[iy]);

            i += 1;
            io += o.inc;
            ix += x.inc;
        }

        while (i < o.len) : (i += 1) {
            if (comptime rinfo != .error_union)
                op_(&o.data[numeric.cast(usize, io)], x.data[numeric.cast(usize, ix)], numeric.zero(types.Numeric(Y)))
            else
                try op_(&o.data[numeric.cast(usize, io)], x.data[numeric.cast(usize, ix)], numeric.zero(types.Numeric(Y)));

            io += o.inc;
            ix += x.inc;
        }
    }
}
