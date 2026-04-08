const types = @import("../../../types.zig");

const numeric = @import("../../../numeric.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));

    var i: usize = 0;
    if (o.inc == 1) {
        var iy: usize = 0;
        while (iy < y.nnz) : (iy += 1) {
            while (i < y.idx[iy]) : (i += 1) {
                o.data[i] = numeric.zero(types.Numeric(O));
            }

            op_(&o.data[i], x, y.data[iy]);

            i += 1;
        }

        while (i < o.len) : (i += 1) {
            o.data[i] = numeric.zero(types.Numeric(O));
        }
    } else {
        var io: isize = if (o.inc < 0) (-numeric.cast(isize, o.len) + 1) * o.inc else 0;
        var iy: usize = 0;

        while (iy < y.nnz) : (iy += 1) {
            while (i < y.idx[iy]) : (i += 1) {
                o.data[numeric.cast(usize, io)] = numeric.zero(types.Numeric(O));

                io += o.inc;
            }

            op_(&o.data[numeric.cast(usize, io)], x, y.data[iy]);

            i += 1;
            io += o.inc;
        }

        while (i < o.len) : (i += 1) {
            o.data[numeric.cast(usize, io)] = numeric.zero(types.Numeric(O));

            io += o.inc;
        }
    }
}
