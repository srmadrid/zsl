const types = @import("../../../types.zig");

const int = @import("../../../int.zig");

const numeric = @import("../../../numeric.zig");
const vector = @import("../../../vector.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) !void {
    if (o.len != y.len or o._dlen < y.nnz or o._ilen < y.nnz)
        return vector.Error.DimensionMismatch;

    o.nnz = y.nnz;

    var i: usize = 0;

    while (i < o.nnz) : (i += 1) {
        op_(&o.data[i], x, y.data[i]);

        o.idx[i] = y.idx[i];
    }
}
