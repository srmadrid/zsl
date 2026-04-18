const types = @import("../../../types.zig");

const int = @import("../../../int.zig");

const numeric = @import("../../../numeric.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));

    if (comptime types.layoutOf(O) == .col_major) {
        var j: usize = 0;
        while (j < o.cols) : (j += 1) {
            if (comptime types.uploOf(O) == .upper) {
                var i: usize = 0;
                while (i < int.min(j, o.rows)) : (i += 1) {
                    o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                }

                if (j < o.rows) {
                    op_(&o.data[o._index(j, j)], x, y.data[j]);
                }
            } else {
                if (j < o.rows) {
                    op_(&o.data[o._index(j, j)], x, y.data[j]);
                }

                var i: usize = int.min(j + 1, o.rows);
                while (i < o.rows) : (i += 1) {
                    o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                }
            }
        }
    } else {
        var i: usize = 0;
        while (i < o.rows) : (i += 1) {
            if (comptime types.uploOf(O) == .lower) {
                var j: usize = 0;
                while (j < int.min(i, o.cols)) : (j += 1) {
                    o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                }

                if (i < o.cols) {
                    op_(&o.data[o._index(i, i)], x, y.data[i]);
                }
            } else {
                if (i < o.cols) {
                    op_(&o.data[o._index(i, i)], x, y.data[i]);
                }

                var j: usize = int.min(i + 1, o.cols);
                while (j < o.cols) : (j += 1) {
                    o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                }
            }
        }
    }
}
