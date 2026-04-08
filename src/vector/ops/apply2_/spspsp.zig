const numeric = @import("../../../numeric.zig");
const vector = @import("../../../vector.zig");

const int = @import("../../../int.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) !void {
    const nnz = int.min(x.nnz + y.nnz, x.len);

    if (o._dlen < nnz or o._ilen < nnz)
        return vector.Error.DimensionMismatch;

    o.nnz = 0;

    var ix: usize = 0;
    var iy: usize = 0;
    while (ix < x.nnz and iy < y.nnz) {
        if (x.idx[ix] == y.idx[iy]) {
            op_(&o.data[o.nnz], x.data[ix], y.data[iy]);

            o.idx[o.nnz] = x.idx[ix];
            o.nnz += 1;
            ix += 1;
            iy += 1;
        } else if (x.idx[ix] < y.idx[iy]) {
            numeric.set(&o.data[o.nnz], x.data[ix]);

            o.idx[o.nnz] = x.idx[ix];
            o.nnz += 1;
            ix += 1;
        } else {
            if (comptime op_ == numeric.add_)
                numeric.set(&o.data[o.nnz], y.data[iy])
            else
                numeric.set(&o.data[o.nnz], numeric.neg(y.data[iy]));

            o.idx[o.nnz] = y.idx[iy];
            o.nnz += 1;
            iy += 1;
        }
    }

    while (ix < x.nnz) : (ix += 1) {
        numeric.set(&o.data[o.nnz], x.data[ix]);

        o.idx[o.nnz] = x.idx[ix];
        o.nnz += 1;
    }

    while (iy < y.nnz) : (iy += 1) {
        if (comptime op_ == numeric.add_)
            numeric.set(&o.data[o.nnz], y.data[iy])
        else
            numeric.set(&o.data[o.nnz], numeric.neg(y.data[iy]));

        o.idx[o.nnz] = y.idx[iy];
        o.nnz += 1;
    }
}
