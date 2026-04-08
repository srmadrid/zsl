const types = @import("../../../types.zig");

const int = @import("../../../int.zig");

const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));

    switch (comptime types.layoutOf(O)) {
        .col_major => return loopColMajor(o, x, y, op_),
        .row_major => return loopRowMajor(o, x, y, op_),
    }
}

inline fn loopColMajor(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));
    const Y: type = @TypeOf(y);

    var j: usize = 0;
    while (j < o.cols) : (j += 1) {
        if (comptime types.uploOf(O) == .upper) {
            var i: usize = 0;
            while (i < int.min(j, o.rows)) : (i += 1) {
                op_(&o.data[o._index(i, j)], x, y.data[y._index(i, j)]);
            }

            if (j < o.rows) {
                if (comptime types.diagOf(Y) == .unit)
                    numeric.set(&o.data[o._index(j, j)], x)
                else
                    op_(&o.data[o._index(j, j)], x, y.data[y._index(j, j)]);
            }
        } else {
            if (j < o.rows) {
                if (comptime types.diagOf(Y) == .unit)
                    numeric.set(&o.data[o._index(j, j)], x)
                else
                    op_(&o.data[o._index(j, j)], x, y.data[y._index(j, j)]);
            }

            var i: usize = int.min(j + 1, o.rows);
            while (i < o.rows) : (i += 1) {
                op_(&o.data[o._index(i, j)], x, y.data[y._index(i, j)]);
            }
        }
    }
}

inline fn loopRowMajor(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));
    const Y: type = @TypeOf(y);

    var i: usize = 0;
    while (i < o.rows) : (i += 1) {
        if (comptime types.uploOf(O) == .lower) {
            var j: usize = 0;
            while (j < int.min(i, o.cols)) : (j += 1) {
                op_(&o.data[o._index(i, j)], x, y.data[y._index(i, j)]);
            }

            if (i < o.cols) {
                if (comptime types.diagOf(Y) == .unit)
                    numeric.set(&o.data[o._index(i, i)], x)
                else
                    op_(&o.data[o._index(i, i)], x, y.data[y._index(i, i)]);
            }
        } else {
            if (i < o.cols) {
                if (comptime types.diagOf(Y) == .unit)
                    numeric.set(&o.data[o._index(i, i)], x)
                else
                    op_(&o.data[o._index(i, i)], x, y.data[y._index(i, i)]);
            }

            var j: usize = int.min(i + 1, o.cols);
            while (j < o.cols) : (j += 1) {
                op_(&o.data[o._index(i, j)], x, y.data[y._index(i, j)]);
            }
        }
    }
}
