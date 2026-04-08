const types = @import("../../../types.zig");

const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));

    switch (comptime types.layoutOf(O)) {
        .col_major => return loopColMajor(o, x, y, op_),
        .row_major => return loopRowMajor(o, x, y, op_),
    }
}

fn loopColMajor(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const Y: type = @TypeOf(y);

    var j: usize = 0;
    while (j < o.cols) : (j += 1) {
        var i: usize = 0;
        while (i < j) : (i += 1) {
            const ty = if (comptime types.uploOf(Y) == .upper) y.data[y._index(i, j)] else y.data[y._index(j, i)];
            op_(&o.data[o._index(i, j)], x, ty);
        }

        op_(&o.data[o._index(j, j)], x, y.data[y._index(j, j)]);

        i = j + 1;
        while (i < o.rows) : (i += 1) {
            const ty = if (comptime types.uploOf(Y) == .lower) y.data[y._index(i, j)] else y.data[y._index(j, i)];
            op_(&o.data[o._index(i, j)], x, ty);
        }
    }
}

fn loopRowMajor(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const Y: type = @TypeOf(y);

    var i: usize = 0;
    while (i < o.rows) : (i += 1) {
        var j: usize = 0;
        while (j < i) : (j += 1) {
            const ty = if (comptime types.uploOf(Y) == .lower) y.data[y._index(i, j)] else y.data[y._index(j, i)];
            op_(&o.data[o._index(i, j)], x, ty);
        }

        op_(&o.data[o._index(i, i)], x, y.data[y._index(i, i)]);

        j = i + 1;
        while (j < o.cols) : (j += 1) {
            const ty = if (comptime types.uploOf(Y) == .upper) y.data[y._index(i, j)] else y.data[y._index(j, i)];
            op_(&o.data[o._index(i, j)], x, ty);
        }
    }
}
