const types = @import("../../../types.zig");

const numeric = @import("../../../numeric.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));

    var i: usize = 0;
    if (o.inc == 1) {
        var ix: usize = 0;
        var iy: usize = 0;

        while (i < o.len) : (i += 1) {
            if (ix < x.nnz and x.idx[ix] == i) {
                if (iy < y.nnz and y.idx[iy] == i) {
                    op_(&o.data[i], x.data[ix], y.data[iy]);

                    ix += 1;
                    iy += 1;
                } else {
                    numeric.set(&o.data[i], x.data[ix]);

                    ix += 1;
                }
            } else {
                if (iy < y.nnz and y.idx[iy] == i) {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[i], y.data[iy])
                    else
                        numeric.set(&o.data[i], numeric.neg(y.data[iy]));

                    iy += 1;
                } else {
                    o.data[i] = numeric.zero(types.Numeric(O));
                }
            }
        }
    } else {
        var io: isize = if (o.inc < 0) (-numeric.cast(isize, o.len) + 1) * o.inc else 0;
        var ix: usize = 0;
        var iy: usize = 0;

        while (i < o.len) : (i += 1) {
            if (ix < x.nnz and x.idx[ix] == i) {
                if (iy < y.nnz and y.idx[iy] == i) {
                    op_(&o.data[numeric.cast(usize, io)], x.data[ix], y.data[iy]);

                    ix += 1;
                    iy += 1;
                } else {
                    numeric.set(&o.data[numeric.cast(usize, io)], x.data[ix]);

                    ix += 1;
                }
            } else {
                if (iy < y.nnz and y.idx[iy] == i) {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[numeric.cast(usize, io)], y.data[iy])
                    else
                        numeric.set(&o.data[numeric.cast(usize, io)], numeric.neg(y.data[iy]));

                    iy += 1;
                } else {
                    o.data[numeric.cast(usize, io)] = numeric.zero(types.Numeric(O));
                }
            }

            io += o.inc;
        }
    }
}
