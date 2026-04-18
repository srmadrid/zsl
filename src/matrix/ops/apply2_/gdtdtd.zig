const types = @import("../../../types.zig");

const int = @import("../../../int.zig");

const numeric = @import("../../../numeric.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    if (comptime types.layoutOf(O) == .col_major) {
        var j: usize = 0;
        while (j < o.cols) : (j += 1) {
            var i: usize = 0;
            if (comptime types.uploOf(X) == .upper) {
                if (comptime types.uploOf(Y) == .upper) {
                    while (i < int.min(j, o.rows)) : (i += 1) {
                        op_(&o.data[o._index(i, j)], x.data[x._index(i, j)], y.data[y._index(i, j)]);
                    }
                } else {
                    while (i < int.min(j, o.rows)) : (i += 1) {
                        numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                    }
                }
            } else {
                if (comptime types.uploOf(Y) == .upper) {
                    while (i < int.min(j, o.rows)) : (i += 1) {
                        if (comptime op_ == numeric.add_)
                            numeric.set(&o.data[o._index(i, j)], y.data[y._index(i, j)])
                        else
                            numeric.set(&o.data[o._index(i, j)], numeric.neg(y.data[y._index(i, j)]));
                    }
                } else {
                    while (i < int.min(j, o.rows)) : (i += 1) {
                        o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                    }
                }
            }

            if (j < o.rows) {
                if (comptime types.diagOf(X) == .unit) {
                    if (comptime types.diagOf(Y) == .unit) {
                        if (comptime op_ == numeric.add_)
                            o.data[o._index(j, j)] = numeric.two(types.Numeric(O))
                        else
                            o.data[o._index(j, j)] = numeric.zero(types.Numeric(O));
                    } else {
                        op_(&o.data[o._index(j, j)], numeric.one(types.Numeric(X)), y.data[y._index(j, j)]);
                    }
                } else {
                    if (comptime types.diagOf(Y) == .unit)
                        op_(&o.data[o._index(j, j)], x.data[x._index(j, j)], numeric.one(types.Numeric(Y)))
                    else
                        op_(&o.data[o._index(j, j)], x.data[x._index(j, j)], y.data[y._index(j, j)]);
                }
            }

            i = int.min(j + 1, o.rows);
            if (comptime types.uploOf(X) == .lower) {
                if (comptime types.uploOf(Y) == .lower) {
                    while (i < o.rows) : (i += 1) {
                        op_(&o.data[o._index(i, j)], x.data[x._index(i, j)], y.data[y._index(i, j)]);
                    }
                } else {
                    while (i < o.rows) : (i += 1) {
                        numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                    }
                }
            } else {
                if (comptime types.uploOf(Y) == .lower) {
                    while (i < o.rows) : (i += 1) {
                        if (comptime op_ == numeric.add_)
                            numeric.set(&o.data[o._index(i, j)], y.data[y._index(i, j)])
                        else
                            numeric.set(&o.data[o._index(i, j)], numeric.neg(y.data[y._index(i, j)]));
                    }
                } else {
                    while (i < o.rows) : (i += 1) {
                        o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                    }
                }
            }
        }
    } else {
        var i: usize = 0;
        while (i < o.rows) : (i += 1) {
            var j: usize = 0;
            if (comptime types.uploOf(X) == .lower) {
                if (comptime types.uploOf(Y) == .lower) {
                    while (j < int.min(i, o.cols)) : (j += 1) {
                        op_(&o.data[o._index(i, j)], x.data[x._index(i, j)], y.data[y._index(i, j)]);
                    }
                } else {
                    while (j < int.min(i, o.cols)) : (j += 1) {
                        numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                    }
                }
            } else {
                if (comptime types.uploOf(Y) == .lower) {
                    while (j < int.min(i, o.cols)) : (j += 1) {
                        if (comptime op_ == numeric.add_)
                            numeric.set(&o.data[o._index(i, j)], y.data[y._index(i, j)])
                        else
                            numeric.set(&o.data[o._index(i, j)], numeric.neg(y.data[y._index(i, j)]));
                    }
                } else {
                    while (j < int.min(i, o.cols)) : (j += 1) {
                        o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                    }
                }
            }

            if (i < o.cols) {
                if (comptime types.diagOf(X) == .unit) {
                    if (comptime types.diagOf(Y) == .unit) {
                        if (comptime op_ == numeric.add_)
                            o.data[o._index(i, i)] = numeric.two(types.Numeric(O))
                        else
                            o.data[o._index(i, i)] = numeric.zero(types.Numeric(O));
                    } else {
                        op_(&o.data[o._index(i, i)], numeric.one(types.Numeric(X)), y.data[y._index(i, i)]);
                    }
                } else {
                    if (comptime types.diagOf(Y) == .unit)
                        op_(&o.data[o._index(i, i)], x.data[x._index(i, i)], numeric.one(types.Numeric(Y)))
                    else
                        op_(&o.data[o._index(i, i)], x.data[x._index(i, i)], y.data[y._index(i, i)]);
                }
            }

            j = int.min(i + 1, o.cols);
            if (comptime types.uploOf(X) == .upper) {
                if (comptime types.uploOf(Y) == .upper) {
                    while (j < o.cols) : (j += 1) {
                        op_(&o.data[o._index(i, j)], x.data[x._index(i, j)], y.data[y._index(i, j)]);
                    }
                } else {
                    while (j < o.cols) : (j += 1) {
                        numeric.set(&o.data[o._index(i, j)], x.data[x._index(i, j)]);
                    }
                }
            } else {
                if (comptime types.uploOf(Y) == .upper) {
                    while (j < o.cols) : (j += 1) {
                        if (comptime op_ == numeric.add_)
                            numeric.set(&o.data[o._index(i, j)], y.data[y._index(i, j)])
                        else
                            numeric.set(&o.data[o._index(i, j)], numeric.neg(y.data[y._index(i, j)]));
                    }
                } else {
                    while (j < o.cols) : (j += 1) {
                        o.data[o._index(i, j)] = numeric.zero(types.Numeric(O));
                    }
                }
            }
        }
    }
}
