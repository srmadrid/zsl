const std = @import("std");

const types = @import("../../../types.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");

const utils = @import("utils.zig");

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    o.setAll(numeric.zero(types.Numeric(O)));

    if (comptime types.layoutOf(X) == types.layoutOf(Y)) {
        var outer: usize = 0;
        while (outer < x.rows) : (outer += 1) {
            var px = x.ptr[outer];
            var py = y.ptr[outer];
            while (px < x.ptr[outer + 1] and py < y.ptr[outer + 1]) {
                if (x.idx[px] == y.idx[py]) {
                    const i_o = if (comptime types.layoutOf(X) == .col_major) x.idx[px] else outer;
                    const j_o = if (comptime types.layoutOf(X) == .col_major) outer else x.idx[px];

                    op_(&o.data[o._index(i_o, j_o)], x.data[px], y.data[py]);

                    if (i_o != j_o) {
                        if (comptime op_ == numeric.add_)
                            numeric.set(&o.data[o._index(j_o, i_o)], numeric.conj(y.data[py]))
                        else
                            numeric.set(&o.data[o._index(j_o, i_o)], numeric.neg(numeric.conj(y.data[py])));
                    }

                    px += 1;
                    py += 1;
                } else if (x.idx[px] < y.idx[py]) {
                    const i_o = if (comptime types.layoutOf(X) == .col_major) x.idx[px] else outer;
                    const j_o = if (comptime types.layoutOf(X) == .col_major) outer else x.idx[px];

                    if (if (comptime types.uploOf(Y) == .upper) i_o <= j_o else i_o >= j_o) {
                        numeric.set(&o.data[o._index(i_o, j_o)], x.data[px]);
                    } else {
                        if (utils.searchSparse(y, j_o, i_o)) |ty|
                            op_(&o.data[o._index(i_o, j_o)], x.data[px], numeric.conj(ty))
                        else
                            numeric.set(&o.data[o._index(i_o, j_o)], x.data[px]);
                    }

                    px += 1;
                } else {
                    const i_o = if (comptime types.layoutOf(Y) == .col_major) y.idx[py] else outer;
                    const j_o = if (comptime types.layoutOf(Y) == .col_major) outer else y.idx[py];

                    if (i_o == j_o and comptime types.diagOf(X) == .unit) {
                        op_(&o.data[o._index(i_o, j_o)], numeric.one(types.Numeric(X)), y.data[py]);
                    } else {
                        if (if (comptime types.uploOf(X) == .upper) i_o <= j_o else i_o >= j_o) {
                            if (utils.searchSparse(x, i_o, j_o) == null) {
                                if (comptime op_ == numeric.add_)
                                    numeric.set(&o.data[o._index(i_o, j_o)], y.data[py])
                                else
                                    numeric.set(&o.data[o._index(i_o, j_o)], numeric.neg(y.data[py]));
                            }
                        } else {
                            if (comptime op_ == numeric.add_)
                                numeric.set(&o.data[o._index(i_o, j_o)], y.data[py])
                            else
                                numeric.set(&o.data[o._index(i_o, j_o)], numeric.neg(y.data[py]));
                        }
                    }

                    if (i_o != j_o) {
                        if (if (comptime types.uploOf(X) == .upper) j_o <= i_o else j_o >= i_o) {
                            if (utils.searchSparse(x, j_o, i_o) == null) {
                                if (comptime op_ == numeric.add_)
                                    numeric.set(&o.data[o._index(j_o, i_o)], numeric.conj(y.data[py]))
                                else
                                    numeric.set(&o.data[o._index(j_o, i_o)], numeric.neg(numeric.conj(y.data[py])));
                            }
                        } else {
                            if (comptime op_ == numeric.add_)
                                numeric.set(&o.data[o._index(j_o, i_o)], numeric.conj(y.data[py]))
                            else
                                numeric.set(&o.data[o._index(j_o, i_o)], numeric.neg(numeric.conj(y.data[py])));
                        }
                    }

                    py += 1;
                }
            }

            while (px < x.ptr[outer + 1]) : (px += 1) {
                const i_o = if (comptime types.layoutOf(X) == .col_major) x.idx[px] else outer;
                const j_o = if (comptime types.layoutOf(X) == .col_major) outer else x.idx[px];

                if (if (comptime types.uploOf(Y) == .upper) i_o <= j_o else i_o >= j_o) {
                    numeric.set(&o.data[o._index(i_o, j_o)], x.data[px]);
                } else {
                    if (utils.searchSparse(y, j_o, i_o)) |ty|
                        op_(&o.data[o._index(i_o, j_o)], x.data[px], numeric.conj(ty))
                    else
                        numeric.set(&o.data[o._index(i_o, j_o)], x.data[px]);
                }
            }

            while (py < y.ptr[outer + 1]) : (py += 1) {
                const i_o = if (comptime types.layoutOf(Y) == .col_major) y.idx[py] else outer;
                const j_o = if (comptime types.layoutOf(Y) == .col_major) outer else y.idx[py];

                if (i_o == j_o and comptime types.diagOf(X) == .unit) {
                    op_(&o.data[o._index(i_o, j_o)], numeric.one(types.Numeric(X)), y.data[py]);
                } else {
                    if (if (comptime types.uploOf(X) == .upper) i_o <= j_o else i_o >= j_o) {
                        if (utils.searchSparse(x, i_o, j_o) == null) {
                            if (comptime op_ == numeric.add_)
                                numeric.set(&o.data[o._index(i_o, j_o)], y.data[py])
                            else
                                numeric.set(&o.data[o._index(i_o, j_o)], numeric.neg(y.data[py]));
                        }
                    } else {
                        if (comptime op_ == numeric.add_)
                            numeric.set(&o.data[o._index(i_o, j_o)], y.data[py])
                        else
                            numeric.set(&o.data[o._index(i_o, j_o)], numeric.neg(y.data[py]));
                    }
                }

                if (i_o != j_o) {
                    if (if (comptime types.uploOf(X) == .upper) j_o <= i_o else j_o >= i_o) {
                        if (utils.searchSparse(x, j_o, i_o) == null) {
                            if (comptime op_ == numeric.add_)
                                numeric.set(&o.data[o._index(j_o, i_o)], numeric.conj(y.data[py]))
                            else
                                numeric.set(&o.data[o._index(j_o, i_o)], numeric.neg(numeric.conj(y.data[py])));
                        }
                    } else {
                        if (comptime op_ == numeric.add_)
                            numeric.set(&o.data[o._index(j_o, i_o)], numeric.conj(y.data[py]))
                        else
                            numeric.set(&o.data[o._index(j_o, i_o)], numeric.neg(numeric.conj(y.data[py])));
                    }
                }
            }
        }
    } else {
        var idx_x_outer: usize = 0;
        while (idx_x_outer < x.rows) : (idx_x_outer += 1) {
            var px = x.ptr[idx_x_outer];
            while (px < x.ptr[idx_x_outer + 1]) : (px += 1) {
                const i_o = if (comptime types.layoutOf(X) == .col_major) x.idx[px] else idx_x_outer;
                const j_o = if (comptime types.layoutOf(X) == .col_major) idx_x_outer else x.idx[px];

                if (if (comptime types.uploOf(Y) == .upper) i_o <= j_o else i_o >= j_o) {
                    if (utils.searchSparse(y, i_o, j_o)) |ty|
                        op_(&o.data[o._index(i_o, j_o)], x.data[px], ty)
                    else
                        numeric.set(&o.data[o._index(i_o, j_o)], x.data[px]);
                } else {
                    if (utils.searchSparse(y, j_o, i_o)) |ty|
                        op_(&o.data[o._index(i_o, j_o)], x.data[px], numeric.conj(ty))
                    else
                        numeric.set(&o.data[o._index(i_o, j_o)], x.data[px]);
                }
            }
        }

        var idx_y_outer: usize = 0;
        while (idx_y_outer < y.rows) : (idx_y_outer += 1) {
            var py = y.ptr[idx_y_outer];
            while (py < y.ptr[idx_y_outer + 1]) : (py += 1) {
                const i_o = if (comptime types.layoutOf(Y) == .col_major) y.idx[py] else idx_y_outer;
                const j_o = if (comptime types.layoutOf(Y) == .col_major) idx_y_outer else y.idx[py];

                if (i_o == j_o and comptime types.diagOf(X) == .unit) {
                    op_(&o.data[o._index(i_o, j_o)], numeric.one(types.Numeric(X)), y.data[py]);
                } else {
                    if (if (comptime types.uploOf(X) == .upper) i_o <= j_o else i_o >= j_o) {
                        if (utils.searchSparse(x, i_o, j_o) == null) {
                            if (comptime op_ == numeric.add_)
                                numeric.set(&o.data[o._index(i_o, j_o)], y.data[py])
                            else
                                numeric.set(&o.data[o._index(i_o, j_o)], numeric.neg(y.data[py]));
                        }
                    } else {
                        if (comptime op_ == numeric.add_)
                            numeric.set(&o.data[o._index(i_o, j_o)], y.data[py])
                        else
                            numeric.set(&o.data[o._index(i_o, j_o)], numeric.neg(y.data[py]));
                    }
                }

                if (i_o != j_o) {
                    if (if (comptime types.uploOf(X) == .upper) j_o <= i_o else j_o >= i_o) {
                        if (utils.searchSparse(x, j_o, i_o) == null) {
                            if (comptime op_ == numeric.add_)
                                numeric.set(&o.data[o._index(j_o, i_o)], numeric.conj(y.data[py]))
                            else
                                numeric.set(&o.data[o._index(j_o, i_o)], numeric.neg(numeric.conj(y.data[py])));
                        }
                    } else {
                        if (comptime op_ == numeric.add_)
                            numeric.set(&o.data[o._index(j_o, i_o)], numeric.conj(y.data[py]))
                        else
                            numeric.set(&o.data[o._index(j_o, i_o)], numeric.neg(numeric.conj(y.data[py])));
                    }
                }
            }
        }
    }

    if (comptime types.diagOf(X) == .unit) {
        var idx: usize = 0;
        while (idx < o.rows) : (idx += 1) {
            if (utils.searchSparse(x, idx, idx) == null and utils.searchSparse(y, idx, idx) == null) {
                numeric.set(&o.data[o._index(idx, idx)], numeric.one(types.Numeric(X)));
            }
        }
    }
}
