const std = @import("std");

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

fn loopColMajor(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);

    const aliased = (comptime O == X) and std.meta.eql(o.*, x);

    var j: usize = 0;
    if (!aliased) {
        while (j < o.cols) : (j += 1) {
            var i: usize = 0;
            while (i < o.rows) : (i += 1) {
                numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
            }
        }
    }

    j = 0;
    while (j < int.min(o.rows, o.cols)) : (j += 1) {
        op_(&o.data[o._index(j, j)], x.data[x._index(j, j)], y.data[j]);
    }
}

fn loopRowMajor(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);

    const aliased = (comptime O == X) and std.meta.eql(o.*, x);

    var i: usize = 0;
    if (!aliased) {
        while (i < o.rows) : (i += 1) {
            var j: usize = 0;
            while (j < o.cols) : (j += 1) {
                numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
            }
        }
    }

    i = 0;
    while (i < int.min(o.rows, o.cols)) : (i += 1) {
        op_(&o.data[o._index(i, i)], x.data[x._index(i, i)], y.data[i]);
    }
}
