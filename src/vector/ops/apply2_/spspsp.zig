const types = @import("../../../types.zig");

const numeric = @import("../../../numeric.zig");
const vector = @import("../../../vector.zig");

const int = @import("../../../int.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) !void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    comptime var R = types.ReturnTypeFromInputs(op_, &.{ *types.Numeric(O), types.Numeric(X), types.Numeric(Y) });
    const rinfo = @typeInfo(R);
    if (rinfo == .error_union)
        R = rinfo.error_union.payload;

    const nnz = int.min(x.nnz + y.nnz, x.len);

    if (o.len != x.len or o.len != y.len or o._dlen < nnz or o._ilen < nnz)
        return vector.Error.DimensionMismatch;

    var ix: usize = 0;
    var iy: usize = 0;
    while (ix < x.nnz and iy < y.nnz) {
        if (x.idx[ix] == y.idx[iy]) {
            if (comptime rinfo != .error_union)
                op_(&o.data[o.nnz], x.data[ix], y.data[iy])
            else
                try op_(&o.data[o.nnz], x.data[ix], y.data[iy]);

            o.idx[o.nnz] = x.idx[ix];
            o.nnz += 1;
            ix += 1;
            iy += 1;
        } else if (x.idx[ix] < y.idx[iy]) {
            if (comptime rinfo != .error_union)
                op_(&o.data[o.nnz], x.data[ix], numeric.zero(types.Numeric(Y)))
            else
                try op_(&o.data[o.nnz], x.data[ix], numeric.zero(types.Numeric(Y)));

            o.idx[o.nnz] = x.idx[ix];
            o.nnz += 1;
            ix += 1;
        } else {
            if (comptime rinfo != .error_union)
                op_(&o.data[o.nnz], numeric.zero(types.Numeric(X)), y.data[iy])
            else
                try op_(&o.data[o.nnz], numeric.zero(types.Numeric(X)), y.data[iy]);

            o.idx[o.nnz] = y.idx[iy];
            o.nnz += 1;
            iy += 1;
        }
    }

    while (ix < x.nnz) : (ix += 1) {
        if (comptime rinfo != .error_union)
            op_(&o.data[o.nnz], x.data[ix], numeric.zero(types.Numeric(Y)))
        else
            try op_(&o.data[o.nnz], x.data[ix], numeric.zero(types.Numeric(Y)));

        o.idx[o.nnz] = x.idx[ix];
        o.nnz += 1;
    }

    while (iy < y.nnz) : (iy += 1) {
        if (comptime rinfo != .error_union)
            op_(&o.data[o.nnz], numeric.zero(types.Numeric(X)), y.data[iy])
        else
            try op_(&o.data[o.nnz], numeric.zero(types.Numeric(X)), y.data[iy]);

        o.idx[o.nnz] = y.idx[iy];
        o.nnz += 1;
    }
}
