const std = @import("std");

const types = @import("../../types.zig");
const Layout = types.Layout;

const numeric = @import("../../numeric.zig");

const matrix = @import("../../matrix.zig");

/// Sparse general matrix type, represented in either CSC or CSR format,
/// depending on if `layout` is column-major or row-major, respectively.
pub fn Sparse(N: type, layout: Layout) type {
    if (!types.isNumeric(N))
        @compileError("zsl.matrix.general.Sparse: N must be a numeric type, got \n\tN = " ++ @typeName(N) ++ "\n");

    return struct {
        data: [*]N,
        idx: [*]usize,
        ptr: [*]usize,
        nnz: usize,
        rows: usize,
        cols: usize,
        flags: matrix.Flags,

        // Type signatures
        pub const is_matrix = true;
        pub const is_sparse = true;
        pub const is_general = true;
        pub const storage_layout = layout;
        pub const storage_uplo = types.default_uplo;
        pub const storage_diag = types.default_diag;

        // Numeric type
        pub const Numeric = N;

        pub const empty: matrix.general.Sparse(N, layout) = .{
            .data = &.{},
            .idx = &.{},
            .ptr = &.{},
            .nnz = 0,
            .rows = 0,
            .cols = 0,
            .flags = .{ .owns_data = false },
        };

        /// Deinitializes the matrix, freeing any allocated memory and
        /// invalidating it.
        ///
        /// ## Arguments
        /// * `self` (`*matrix.general.Sparse(N, layout)`): A pointer to the
        ///   matrix to deinitialize.
        /// * `allocator` (`std.mem.Allocator`): The allocator to use for memory
        ///   deallocation. Must be the same allocator used to compile `self`.
        ///
        /// ## Returns
        /// `void`
        pub fn deinit(self: *matrix.general.Sparse(N, layout), allocator: std.mem.Allocator) void {
            if (self.flags.owns_data) {
                allocator.free(self.data[0..self.nnz]);
                allocator.free(self.idx[0..self.nnz]);
                allocator.free(self.ptr[0..(if (comptime layout == .col_major) self.cols + 1 else self.rows + 1)]);
            }

            self.* = undefined;
        }

        /// Gets the element at the specified index.
        ///
        /// ## Arguments
        /// * `self` (`matrix.general.Sparse(N, layout)`): The matrix to get the
        ///   element from.
        /// * `r` (`usize`): The row index of the element to get.
        /// * `c` (`usize`): The column index of the element to get.
        ///
        /// ## Returns
        /// `N`: The element at the specified index.
        ///
        /// ## Errors
        /// * `matrix.Error.PositionOutOfBounds`: If `r` or `c` is out of
        ///   bounds.
        pub fn get(self: matrix.general.Sparse(N, layout), r: usize, c: usize) !N {
            if (r >= self.rows or c >= self.cols)
                return matrix.Error.PositionOutOfBounds;

            const major = if (comptime layout == .col_major) c else r;
            const minor = if (comptime layout == .col_major) r else c;

            var left: usize = self.ptr[major];
            var right: usize = self.ptr[major + 1];
            while (left < right) {
                const mid = left + (right - left) / 2;
                const mid_idx = self.idx[mid];

                if (mid_idx == minor) {
                    return self.data[mid];
                } else if (mid_idx < minor) {
                    left = mid + 1;
                } else {
                    right = mid;
                }
            }

            return numeric.zero(N);
        }

        /// Sets the element at the specified index.
        ///
        /// ## Arguments
        /// * `self` (`*matrix.general.Sparse(N, layout)`): A pointer to the
        ///   matrix to set the element in.
        /// * `r` (`usize`): The row index of the element to set.
        /// * `c` (`usize`): The column index of the element to set.
        /// * `value` (`N`): The value to set the element to.
        ///
        /// ## Returns
        /// `void`
        ///
        /// ## Errors
        /// * `matrix.Error.PositionOutOfBounds`: If `r` or `c` is out of
        ///   bounds.
        /// * `matrix.Error.BreaksStructure`: If no existing element is present
        ///   at the specified index.
        pub fn set(self: *matrix.general.Sparse(N, layout), r: usize, c: usize, value: N) !void {
            if (r >= self.rows or c >= self.cols)
                return matrix.Error.PositionOutOfBounds;

            const major = if (comptime layout == .col_major) c else r;
            const minor = if (comptime layout == .col_major) r else c;

            var left: usize = self.ptr[major];
            var right: usize = self.ptr[major + 1];
            while (left < right) {
                const mid = left + (right - left) / 2;
                const mid_idx = self.idx[mid];

                if (mid_idx == minor) {
                    self.data[mid] = value;
                    return;
                } else if (mid_idx < minor) {
                    left = mid + 1;
                } else {
                    right = mid;
                }
            }

            return matrix.Error.BreaksStructure;
        }
    };
}
