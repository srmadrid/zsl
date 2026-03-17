const types = @import("../../../types.zig");

const numeric = @import("../../../numeric.zig");
const vector = @import("../../../vector.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) !void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    comptime var R = types.ReturnTypeFromInputs(op_, &.{ *types.Numeric(O), types.Numeric(X), Y });
    const rinfo = @typeInfo(R);
    if (rinfo == .error_union)
        R = rinfo.error_union.payload;

    if (o.len != x.len or o._dlen < x.nnz or o._ilen < x.nnz)
        return vector.Error.DimensionMismatch;

    o.nnz = x.nnz;

    var i: usize = 0;
    while (i < x.nnz) : (i += 1) {
        if (comptime rinfo != .error_union)
            op_(&o.data[i], x.data[i], y)
        else
            try op_(&o.data[i], x.data[i], y);

        o.idx[i] = x.idx[i];
    }
}
