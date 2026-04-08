const std = @import("std");

const types = @import("../../../types.zig");
const int = @import("../../../int.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    if (comptime types.layoutOf(O) == .col_major) {
        var j: usize = 0;
        while (j < o.cols) : (j += 1) {
            if (comptime types.uploOf(X) == .upper) {
                var i: usize = 0;
                while (i < int.min(j, o.rows)) : (i += 1) {
                    numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                }

                if (j < o.rows) {
                    if (comptime types.diagOf(X) == .unit) {
                        if (comptime types.diagOf(Y) == .unit) {
                            if (comptime op_ == numeric.add_)
                                o.data[o._index(j, j)] = numeric.two(types.Numeric(O))
                            else
                                o.data[o._index(j, j)] = numeric.zero(types.Numeric(O));
                        } else {
                            o.data[o._index(j, j)] = numeric.one(types.Numeric(O));
                        }
                    } else {
                        if (comptime types.diagOf(Y) == .unit)
                            op_(&o.data[o._index(j, j)], x.data[x._index(j, j)], numeric.one(types.Numeric(O)))
                        else
                            numeric.set(&o.data[o._index(j, j)], x.data[x._index(j, j)]);
                    }
                }

                i = int.min(j + 1, o.rows);
                while (i < o.rows) : (i += 1) {
                    o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                }
            } else {
                var i: usize = 0;
                while (i < int.min(j, o.rows)) : (i += 1) {
                    o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                }

                if (j < o.rows) {
                    if (comptime types.diagOf(X) == .unit) {
                        if (comptime types.diagOf(Y) == .unit) {
                            if (comptime op_ == numeric.add_)
                                o.data[o._index(j, j)] = numeric.two(types.Numeric(O))
                            else
                                o.data[o._index(j, j)] = numeric.zero(types.Numeric(O));
                        } else {
                            o.data[o._index(j, j)] = numeric.one(types.Numeric(O));
                        }
                    } else {
                        if (comptime types.diagOf(Y) == .unit)
                            op_(&o.data[o._index(j, j)], x.data[x._index(j, j)], numeric.one(types.Numeric(O)))
                        else
                            numeric.set(&o.data[o._index(j, j)], x.data[x._index(j, j)]);
                    }
                }

                i = int.min(j + 1, o.rows);
                while (i < o.rows) : (i += 1) {
                    numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                }
            }
        }
    } else {
        var i: usize = 0;
        while (i < o.rows) : (i += 1) {
            if (comptime types.uploOf(X) == .lower) {
                var j: usize = 0;
                while (j < int.min(i, o.cols)) : (j += 1) {
                    numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                }

                if (i < o.cols) {
                    if (comptime types.diagOf(X) == .unit) {
                        if (comptime types.diagOf(Y) == .unit) {
                            if (comptime op_ == numeric.add_)
                                o.data[o._index(i, i)] = numeric.two(types.Numeric(O))
                            else
                                o.data[o._index(i, i)] = numeric.zero(types.Numeric(O));
                        } else {
                            o.data[o._index(i, i)] = numeric.one(types.Numeric(O));
                        }
                    } else {
                        if (comptime types.diagOf(Y) == .unit)
                            op_(&o.data[o._index(i, i)], x.data[x._index(i, i)], numeric.one(types.Numeric(O)))
                        else
                            numeric.set(&o.data[o._index(i, i)], x.data[x._index(i, i)]);
                    }
                }

                j = int.min(i + 1, o.cols);
                while (j < o.cols) : (j += 1) {
                    o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                }
            } else {
                var j: usize = 0;
                while (j < int.min(i, o.cols)) : (j += 1) {
                    o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                }

                if (i < o.cols) {
                    if (comptime types.diagOf(X) == .unit) {
                        if (comptime types.diagOf(Y) == .unit) {
                            if (comptime op_ == numeric.add_)
                                o.data[o._index(i, i)] = numeric.two(types.Numeric(O))
                            else
                                o.data[o._index(i, i)] = numeric.zero(types.Numeric(O));
                        } else {
                            o.data[o._index(i, i)] = numeric.one(types.Numeric(O));
                        }
                    } else {
                        if (comptime types.diagOf(Y) == .unit)
                            op_(&o.data[o._index(i, i)], x.data[x._index(i, i)], numeric.one(types.Numeric(O)))
                        else
                            numeric.set(&o.data[o._index(i, i)], x.data[x._index(i, i)]);
                    }
                }

                j = int.min(i + 1, o.cols);
                while (j < o.cols) : (j += 1) {
                    numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                }
            }
        }
    }

    if (comptime types.layoutOf(Y) == .col_major) {
        var j: usize = 0;
        while (j < y.cols) : (j += 1) {
            var p: usize = y.ptr[j];
            while (p < y.ptr[j + 1]) : (p += 1) {
                const tx = if (y.idx[p] == j)
                    (if (comptime types.diagOf(X) == .unit) numeric.one(types.Numeric(X)) else x.data[x._index(j, j)])
                else if (y.idx[p] < j)
                    (if (comptime types.uploOf(X) == .upper) x.data[x._index(y.idx[p], j)] else numeric.zero(types.Numeric(X)))
                else
                    (if (comptime types.uploOf(X) == .lower) x.data[x._index(y.idx[p], j)] else numeric.zero(types.Numeric(X)));

                op_(&o.data[o._index(y.idx[p], j)], tx, y.data[p]);
            }
        }
    } else {
        var i: usize = 0;
        while (i < y.rows) : (i += 1) {
            var p: usize = y.ptr[i];
            while (p < y.ptr[i + 1]) : (p += 1) {
                const tx = if (i == y.idx[p])
                    (if (comptime types.diagOf(X) == .unit) numeric.one(types.Numeric(X)) else x.data[x._index(i, i)])
                else if (i < y.idx[p])
                    (if (comptime types.uploOf(X) == .upper) x.data[x._index(i, y.idx[p])] else numeric.zero(types.Numeric(X)))
                else
                    (if (comptime types.uploOf(X) == .lower) x.data[x._index(i, y.idx[p])] else numeric.zero(types.Numeric(X)));

                op_(&o.data[o._index(i, y.idx[p])], tx, y.data[p]);
            }
        }
    }
}
