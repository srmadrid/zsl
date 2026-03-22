const types = @import("../../../types.zig");

const int = @import("../../../int.zig");

const numeric = @import("../../../numeric.zig");
const vector = @import("../../../vector.zig");

const simd = @import("../../../simd.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) !void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    comptime var R = types.ReturnTypeFromInputs(op_, &.{ *types.Numeric(O), X, types.Numeric(Y) });
    const rinfo = @typeInfo(R);
    if (rinfo == .error_union)
        R = rinfo.error_union.payload;

    if (o.len != y.len or o._dlen < y.nnz or o._ilen < y.nnz)
        return vector.Error.DimensionMismatch;

    o.nnz = y.nnz;

    var i: usize = 0;
    if (comptime op_ == numeric.mul_ or op_ == numeric.div_) {
        const sblo = simd.suggestBaseLength(types.Numeric(O));
        const sblx = simd.suggestBaseLength(X);
        const sbly = simd.suggestBaseLength(types.Numeric(Y));

        if (comptime sblo != null and sblx != null and sbly != null) {
            const bl = int.min(sblo.?, int.min(sblx.?, sbly.?));
            const len = o.nnz - (o.nnz % bl);

            while (i < len) : (i += bl) {
                if (comptime op_ == numeric.mul_)
                    simd.mul_(o.data + i, x, y.data + i, bl)
                else
                    simd.div_(o.data + i, x, y.data + i, bl);

                simd.set(o.idx + i, y.idx + i, bl);
            }
        }
    }

    while (i < o.nnz) : (i += 1) {
        if (comptime rinfo != .error_union)
            op_(&o.data[i], x, y.data[i])
        else
            try op_(&o.data[i], x, y.data[i]);

        o.idx[i] = y.idx[i];
    }
}
