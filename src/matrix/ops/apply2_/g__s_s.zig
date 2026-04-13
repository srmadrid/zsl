const std = @import("std");

const types = @import("../../../types.zig");
const int = @import("../../../int.zig");
const numeric = @import("../../../numeric.zig");
const matrix = @import("../../../matrix.zig");
const utils = @import("utils.zig");

fn getLogicalValue(mat: anytype, r: usize, c: usize, comptime skip_primary_search: bool) types.Numeric(@TypeOf(mat)) {
    const M = @TypeOf(mat);

    if (!skip_primary_search) {
        if (utils.searchSparse(mat, r, c)) |v|
            return v;
    }

    if (comptime types.isSymmetricMatrix(M) or types.isHermitianMatrix(M)) {
        if (utils.searchSparse(mat, c, r)) |v| {
            return if (comptime types.isHermitianMatrix(M)) numeric.conj(v) else v;
        }
    }

    if (r == c and comptime types.diagOf(M) == .unit)
        return numeric.one(types.Numeric(M));

    return numeric.zero(types.Numeric(M));
}

fn processCoordinate(o: anytype, x: anytype, y: anytype, i_o: usize, j_o: usize, val_x: anytype, val_y: anytype, comptime op_: anytype) void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    if (comptime types.isSparseMatrix(O)) {
        var val_o: types.Numeric(O) = undefined;
        op_(&val_o, val_x, val_y);
        o.appendAssumeCapacity(i_o, j_o, val_o);
    } else {
        op_(&o.data[o._index(i_o, j_o)], val_x, val_y);
    }

    if (comptime types.isSymmetricMatrix(X) or types.isHermitianMatrix(X) or
        types.isSymmetricMatrix(Y) or types.isHermitianMatrix(Y))
    {
        if (i_o != j_o) {
            const x_hits_naturally = utils.searchSparse(x, j_o, i_o) != null;
            var y_hits_naturally = utils.searchSparse(y, j_o, i_o) != null;

            if ((comptime types.layoutOf(X) != types.layoutOf(Y)) and
                (comptime types.isSymmetricMatrix(X) or types.isHermitianMatrix(X)) and
                (comptime types.isSymmetricMatrix(Y) or types.isHermitianMatrix(Y)) and
                utils.searchSparse(x, i_o, j_o) != null)
            {
                y_hits_naturally = false;
            }

            if (!x_hits_naturally and !y_hits_naturally) {
                const mirror_x = if (comptime types.isSymmetricMatrix(X)) val_x else if (comptime types.isHermitianMatrix(X)) numeric.conj(val_x) else numeric.zero(types.Numeric(X));
                const mirror_y = if (comptime types.isSymmetricMatrix(Y)) val_y else if (comptime types.isHermitianMatrix(Y)) numeric.conj(val_y) else numeric.zero(types.Numeric(Y));

                if (comptime types.isSparseMatrix(O)) {
                    var val_o: types.Numeric(O) = undefined;
                    op_(&val_o, mirror_x, mirror_y);
                    o.appendAssumeCapacity(j_o, i_o, val_o);
                } else {
                    op_(&o.data[o._index(j_o, i_o)], mirror_x, mirror_y);
                }
            }
        }
    }
}

pub fn apply2_(o: anytype, x: anytype, y: anytype, comptime op_: anytype) !void {
    const O: type = types.Child(@TypeOf(o));
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    if (comptime types.isSparseMatrix(O)) {
        const nnz =
            x.nnz * (if (comptime types.isSymmetricMatrix(X) or types.isHermitianMatrix(X)) 2 else 1) +
            y.nnz * (if (comptime types.isSymmetricMatrix(Y) or types.isHermitianMatrix(Y)) 2 else 1);

        if (o._dlen < nnz or o._rlen < nnz or o._clen < nnz)
            return matrix.Error.InsuficientSpace;

        o.nnz = 0;
    } else {
        o.setAll(numeric.zero(types.Numeric(O)));
    }

    if (comptime types.layoutOf(X) == types.layoutOf(Y)) {
        var outer: usize = 0;
        const limit = if (comptime types.layoutOf(X) == .col_major) o.cols else o.rows;

        while (outer < limit) : (outer += 1) {
            var px = x.ptr[outer];
            var py = y.ptr[outer];

            while (px < x.ptr[outer + 1] and py < y.ptr[outer + 1]) {
                var i_o: usize = undefined;
                var j_o: usize = undefined;

                if (x.idx[px] == y.idx[py]) {
                    i_o = if (comptime types.layoutOf(X) == .col_major) x.idx[px] else outer;
                    j_o = if (comptime types.layoutOf(X) == .col_major) outer else x.idx[px];

                    processCoordinate(o, x, y, i_o, j_o, x.data[px], y.data[py], op_);

                    px += 1;
                    py += 1;
                } else if (x.idx[px] < y.idx[py]) {
                    i_o = if (comptime types.layoutOf(X) == .col_major) x.idx[px] else outer;
                    j_o = if (comptime types.layoutOf(X) == .col_major) outer else x.idx[px];

                    processCoordinate(o, x, y, i_o, j_o, x.data[px], getLogicalValue(y, i_o, j_o, true), op_);

                    px += 1;
                } else {
                    i_o = if (comptime types.layoutOf(Y) == .col_major) y.idx[py] else outer;
                    j_o = if (comptime types.layoutOf(Y) == .col_major) outer else y.idx[py];

                    processCoordinate(o, x, y, i_o, j_o, getLogicalValue(x, i_o, j_o, true), y.data[py], op_);

                    py += 1;
                }
            }

            while (px < x.ptr[outer + 1]) : (px += 1) {
                const i_o = if (comptime types.layoutOf(X) == .col_major) x.idx[px] else outer;
                const j_o = if (comptime types.layoutOf(X) == .col_major) outer else x.idx[px];

                processCoordinate(o, x, y, i_o, j_o, x.data[px], getLogicalValue(y, i_o, j_o, true), op_);
            }

            while (py < y.ptr[outer + 1]) : (py += 1) {
                const i_o = if (comptime types.layoutOf(Y) == .col_major) y.idx[py] else outer;
                const j_o = if (comptime types.layoutOf(Y) == .col_major) outer else y.idx[py];

                processCoordinate(o, x, y, i_o, j_o, getLogicalValue(x, i_o, j_o, true), y.data[py], op_);
            }
        }
    } else {
        var idx_x_outer: usize = 0;
        while (idx_x_outer < if (comptime types.layoutOf(X) == .col_major) x.cols else x.rows) : (idx_x_outer += 1) {
            var px = x.ptr[idx_x_outer];
            while (px < x.ptr[idx_x_outer + 1]) : (px += 1) {
                const i_o = if (comptime types.layoutOf(X) == .col_major) x.idx[px] else idx_x_outer;
                const j_o = if (comptime types.layoutOf(X) == .col_major) idx_x_outer else x.idx[px];

                const val_y = getLogicalValue(y, i_o, j_o, false);
                processCoordinate(o, x, y, i_o, j_o, x.data[px], val_y, op_);
            }
        }

        var idx_y_outer: usize = 0;
        while (idx_y_outer < if (comptime types.layoutOf(Y) == .col_major) y.cols else y.rows) : (idx_y_outer += 1) {
            var py = y.ptr[idx_y_outer];
            while (py < y.ptr[idx_y_outer + 1]) : (py += 1) {
                const i_o = if (comptime types.layoutOf(Y) == .col_major) y.idx[py] else idx_y_outer;
                const j_o = if (comptime types.layoutOf(Y) == .col_major) idx_y_outer else y.idx[py];

                const processed_in_x = utils.searchSparse(x, i_o, j_o) != null or
                    ((comptime types.isSymmetricMatrix(X) or types.isHermitianMatrix(X)) and
                        (comptime types.isSymmetricMatrix(Y) or types.isHermitianMatrix(Y)) and
                        utils.searchSparse(x, j_o, i_o) != null);

                if (!processed_in_x) {
                    const val_x = getLogicalValue(x, i_o, j_o, true);
                    processCoordinate(o, x, y, i_o, j_o, val_x, y.data[py], op_);
                }
            }
        }
    }

    if (comptime types.diagOf(X) == .unit or types.diagOf(Y) == .unit) {
        var idx: usize = 0;
        while (idx < int.min(o.rows, o.cols)) : (idx += 1) {
            if (utils.searchSparse(x, idx, idx) == null and utils.searchSparse(y, idx, idx) == null) {
                processCoordinate(o, x, y, idx, idx, getLogicalValue(x, idx, idx, true), getLogicalValue(y, idx, idx, true), op_);
            }
        }
    }
}
