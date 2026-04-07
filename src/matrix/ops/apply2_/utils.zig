const types = @import("../../../types.zig");

/// Binary search for sparse matrix elements
pub fn searchSparse(mat: anytype, row: usize, col: usize) ?types.Numeric(@TypeOf(mat)) {
    if (comptime types.layoutOf(@TypeOf(mat)) == .col_major) {
        var p = mat.ptr[col];
        var p_end = mat.ptr[col + 1];
        while (p < p_end) {
            const mid = p + (p_end - p) / 2;
            if (mat.idx[mid] == row)
                return mat.data[mid];

            if (mat.idx[mid] < row)
                p = mid + 1
            else
                p_end = mid;
        }
    } else {
        var p = mat.ptr[row];
        var p_end = mat.ptr[row + 1];
        while (p < p_end) {
            const mid = p + (p_end - p) / 2;
            if (mat.idx[mid] == col)
                return mat.data[mid];

            if (mat.idx[mid] < col)
                p = mid + 1
            else
                p_end = mid;
        }
    }

    return null;
}
