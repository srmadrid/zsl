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
    const X: type = @TypeOf(x);

    var j: usize = 0;
    while (j < o.cols) : (j += 1) {
        var i: usize = 0;
        while (i < j) : (i += 1) {
            const tx = if (comptime types.uploOf(X) == .upper) x.data[x._index(i, j)] else numeric.conj(x.data[x._index(j, i)]);
            op_(&o.data[o._index(i, j)], tx, y);
        }

        op_(&o.data[o._index(j, j)], x.data[x._index(j, j)], y);

        i = j + 1;
        while (i < o.rows) : (i += 1) {
            const tx = if (comptime types.uploOf(X) == .lower) x.data[x._index(i, j)] else numeric.conj(x.data[x._index(j, i)]);
            op_(&o.data[o._index(i, j)], tx, y);
        }
    }
}

inline fn loopRowMajor(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const X: type = @TypeOf(x);

    var i: usize = 0;
    while (i < o.rows) : (i += 1) {
        var j: usize = 0;
        while (j < i) : (j += 1) {
            const tx = if (comptime types.uploOf(X) == .lower) x.data[x._index(i, j)] else numeric.conj(x.data[x._index(j, i)]);
            op_(&o.data[o._index(i, j)], tx, y);
        }

        op_(&o.data[o._index(i, i)], x.data[x._index(i, i)], y);

        j = i + 1;
        while (j < o.cols) : (j += 1) {
            const tx = if (comptime types.uploOf(X) == .upper) x.data[x._index(i, j)] else numeric.conj(x.data[x._index(j, i)]);
            op_(&o.data[o._index(i, j)], tx, y);
        }
    }
}
