const types = @import("../../../types.zig");

const numeric = @import("../../../numeric.zig");
const vector = @import("../../../vector.zig");

const int = @import("../../../int.zig");

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
    if (o.inc == 1) {
        var ix: usize = 0;
        while (ix < x.nnz) : (ix += 1) {
            while (i < x.idx[ix]) : (i += 1) {
                if (comptime rinfo != .error_union)
                    op_(&o.data[i], numeric.zero(types.Numeric(X)), y)
                else
                    try op_(&o.data[i], numeric.zero(types.Numeric(X)), y);
            }

            if (comptime rinfo != .error_union)
                op_(&o.data[i], x.data[ix], y)
            else
                try op_(&o.data[i], x.data[ix], y);

            i += 1;
        }

        while (i < o.len) : (i += 1) {
            if (comptime rinfo != .error_union)
                op_(&o.data[i], numeric.zero(types.Numeric(X)), y)
            else
                try op_(&o.data[i], numeric.zero(types.Numeric(X)), y);
        }
    } else {
        var io: isize = if (o.inc < 0) (-numeric.cast(isize, o.len) + 1) * o.inc else 0;
        var ix: usize = 0;

        while (ix < x.nnz) : (ix += 1) {
            while (i < x.idx[ix]) : (i += 1) {
                if (comptime rinfo != .error_union)
                    op_(&o.data[numeric.cast(usize, io)], numeric.zero(types.Numeric(X)), y)
                else
                    try op_(&o.data[numeric.cast(usize, io)], numeric.zero(types.Numeric(X)), y);

                io += o.inc;
            }

            if (comptime rinfo != .error_union)
                op_(&o.data[numeric.cast(usize, io)], x.data[ix], y)
            else
                try op_(&o.data[numeric.cast(usize, io)], x.data[ix], y);

            i += 1;
            io += o.inc;
        }

        while (i < o.len) : (i += 1) {
            if (comptime rinfo != .error_union)
                op_(&o.data[numeric.cast(usize, io)], numeric.zero(types.Numeric(X)), y)
            else
                try op_(&o.data[numeric.cast(usize, io)], numeric.zero(types.Numeric(X)), y);

            io += o.inc;
        }
    }
}
