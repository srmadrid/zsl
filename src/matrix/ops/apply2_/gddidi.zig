const types = @import("../../../types.zig");

const int = @import("../../../int.zig");

const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) !void {
    const O: type = types.Child(@TypeOf(o));

    if (o.rows != x.rows or o.cols != x.cols or
        o.rows != y.rows or o.cols != y.cols)
        return matrix.Error.DimensionMismatch;

    switch (comptime types.layoutOf(O)) {
        .col_major => return loopColMajor(o, x, y, op_),
        .row_major => return loopRowMajor(o, x, y, op_),
    }
}

inline fn loopColMajor(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));

    var j: usize = 0;
    while (j < o.cols) : (j += 1) {
        var i: usize = 0;
        while (i < int.min(j, o.rows)) : (i += 1) {
            o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
        }

        if (j < o.rows) {
            op_(&o.data[o._index(j, j)], x.data[j], y.data[j]);
        }

        i = int.min(j + 1, o.rows);
        while (i < o.rows) : (i += 1) {
            o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
        }
    }
}

inline fn loopRowMajor(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));

    var i: usize = 0;
    while (i < o.rows) : (i += 1) {
        var j: usize = 0;
        while (j < int.min(i, o.cols)) : (j += 1) {
            o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
        }

        if (i < o.cols) {
            op_(&o.data[o._index(i, i)], x.data[i], y.data[i]);
        }

        j = int.min(i + 1, o.cols);
        while (j < o.cols) : (j += 1) {
            o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
        }
    }
}
