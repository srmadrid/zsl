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

inline fn loopColMajor(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));

    var j: usize = 0;
    while (j < o.cols) : (j += 1) {
        if (comptime types.uploOf(O) == .upper) {
            var i: usize = 0;
            while (i < j) : (i += 1) {
                o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
            }

            op_(&o.data[o._index(j, j)], x.data[j], y);
        } else {
            op_(&o.data[o._index(j, j)], x.data[j], y);

            var i: usize = j + 1;
            while (i < o.rows) : (i += 1) {
                o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
            }
        }
    }
}

inline fn loopRowMajor(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));

    var i: usize = 0;
    while (i < o.rows) : (i += 1) {
        if (comptime types.uploOf(O) == .lower) {
            var j: usize = 0;
            while (j < i) : (j += 1) {
                o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
            }

            op_(&o.data[o._index(i, i)], x.data[i], y);
        } else {
            op_(&o.data[o._index(i, i)], x.data[i], y);

            var j: usize = i + 1;
            while (j < o.cols) : (j += 1) {
                o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
            }
        }
    }
}
