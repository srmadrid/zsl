const std = @import("std");

const meta = @import("../../../meta.zig");

const numeric = @import("../../../numeric.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = meta.Child(@TypeOf(o));
    const Y: type = @TypeOf(y);

    const aliased = (comptime O == Y) and std.meta.eql(o.*, y);

    if ((comptime op_ == numeric.add_) and aliased) {
        if (o.inc == 1) {
            var ix: usize = 0;
            while (ix < x.nnz) : (ix += 1) {
                op_(&o.data[x.idx[ix]], x.data[ix], y.data[x.idx[ix]]);
            }
        } else {
            const io: isize = if (o.inc < 0) (-numeric.cast(isize, o.len) + 1) * o.inc else 0;
            var ix: usize = 0;
            while (ix < x.nnz) : (ix += 1) {
                const idx = numeric.cast(usize, io + numeric.cast(isize, x.idx[ix]) * o.inc);
                op_(&o.data[idx], x.data[ix], y.data[idx]);
            }
        }
    } else {
        var i: usize = 0;
        if (o.inc == 1 and y.inc == 1) {
            var ix: usize = 0;
            while (ix < x.nnz) : (ix += 1) {
                while (i < x.idx[ix]) : (i += 1) {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[i], y.data[i])
                    else
                        numeric.set(&o.data[i], numeric.neg(y.data[i]));
                }

                op_(&o.data[i], x.data[ix], y.data[i]);

                i += 1;
            }

            while (i < o.len) : (i += 1) {
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[i], y.data[i])
                else
                    numeric.set(&o.data[i], numeric.neg(y.data[i]));
            }
        } else {
            var io: isize = if (o.inc < 0) (-numeric.cast(isize, o.len) + 1) * o.inc else 0;
            var ix: usize = 0;
            var iy: isize = if (y.inc < 0) (-numeric.cast(isize, y.len) + 1) * y.inc else 0;

            while (ix < x.nnz) : (ix += 1) {
                while (i < x.idx[ix]) : (i += 1) {
                    if (comptime op_ == numeric.add_)
                        numeric.set(&o.data[numeric.cast(usize, io)], y.data[numeric.cast(usize, iy)])
                    else
                        numeric.set(&o.data[numeric.cast(usize, io)], numeric.neg(y.data[numeric.cast(usize, iy)]));

                    io += o.inc;
                    iy += y.inc;
                }

                op_(&o.data[numeric.cast(usize, io)], x.data[ix], y.data[numeric.cast(usize, iy)]);

                i += 1;
                io += o.inc;
                iy += y.inc;
            }

            while (i < o.len) : (i += 1) {
                if (comptime op_ == numeric.add_)
                    numeric.set(&o.data[numeric.cast(usize, io)], y.data[numeric.cast(usize, iy)])
                else
                    numeric.set(&o.data[numeric.cast(usize, io)], numeric.neg(y.data[numeric.cast(usize, iy)]));

                io += o.inc;
                iy += y.inc;
            }
        }
    }
}
