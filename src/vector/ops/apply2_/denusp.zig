const types = @import("../../../types.zig");

const numeric = @import("../../../numeric.zig");
const vector = @import("../../../vector.zig");

const int = @import("../../../int.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) !void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    comptime var R = types.ReturnTypeFromInputs(op_, &.{ *types.Numeric(O), X, types.Numeric(Y) });
    const rinfo = @typeInfo(R);
    if (rinfo == .error_union)
        R = rinfo.error_union.payload;

    if (o.len != y.len)
        return vector.Error.DimensionMismatch;

    var i: usize = 0;
    if (o.inc == 1) {
        var iy: usize = 0;
        while (iy < y.nnz) : (iy += 1) {
            while (i < y.idx[iy]) : (i += 1) {
                if (comptime rinfo != .error_union)
                    op_(&o.data[i], x, numeric.zero(types.Numeric(Y)))
                else
                    try op_(&o.data[i], x, numeric.zero(types.Numeric(Y)));
            }

            if (comptime rinfo != .error_union)
                op_(&o.data[i], x, y.data[iy])
            else
                try op_(&o.data[i], x, y.data[iy]);

            i += 1;
        }

        while (i < o.len) : (i += 1) {
            if (comptime rinfo != .error_union)
                op_(&o.data[i], x, numeric.zero(types.Numeric(Y)))
            else
                try op_(&o.data[i], x, numeric.zero(types.Numeric(Y)));
        }
    } else {
        var io: isize = if (o.inc < 0) (-numeric.cast(isize, o.len) + 1) * o.inc else 0;
        var iy: usize = 0;

        while (iy < y.nnz) : (iy += 1) {
            while (i < y.idx[iy]) : (i += 1) {
                if (comptime rinfo != .error_union)
                    op_(&o.data[numeric.cast(usize, io)], x, numeric.zero(types.Numeric(Y)))
                else
                    try op_(&o.data[numeric.cast(usize, io)], x, numeric.zero(types.Numeric(Y)));

                io += o.inc;
            }

            if (comptime rinfo != .error_union)
                op_(&o.data[numeric.cast(usize, io)], x, y.data[iy])
            else
                try op_(&o.data[numeric.cast(usize, io)], x, y.data[iy]);

            i += 1;
            io += o.inc;
        }

        while (i < o.len) : (i += 1) {
            if (comptime rinfo != .error_union)
                op_(&o.data[numeric.cast(usize, io)], x, numeric.zero(types.Numeric(Y)))
            else
                try op_(&o.data[numeric.cast(usize, io)], x, numeric.zero(types.Numeric(Y)));

            io += o.inc;
        }
    }
}
