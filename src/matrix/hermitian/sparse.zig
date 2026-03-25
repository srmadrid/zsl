const std = @import("std");

const types = @import("../../types.zig");
const Layout = types.Layout;
const Uplo = types.Uplo;

const numeric = @import("../../numeric.zig");

const matrix = @import("../../matrix.zig");

/// Sparse Hermitian matrix type, represented in either CSC or CSR format,
/// depending on if `layout` is column-major or row-major, respectively. Only
/// the upper or lower triangular part of the matrix is stored, depending on the
/// `uplo` parameter.
pub fn Sparse(N: type, uplo: Uplo, layout: Layout) type {
    if (!types.isNumeric(N) or !types.isComplex(N))
        @compileError("zsl.matrix.hermitian.Sparse: N must be a complex numeric type, got \n\tN = " ++ @typeName(N) ++ "\n");

    return struct {
        data: [*]N,
        idx: [*]usize,
        ptr: [*]usize,
        nnz: usize,
        size: usize,
        flags: matrix.Flags,

        // Type signatures
        pub const is_matrix = true;
        pub const is_sparse = true;
        pub const is_hermitian = true;
        pub const storage_layout = layout;
        pub const storage_uplo = uplo;
        pub const storage_diag = types.default_diag;

        // Numeric type
        pub const Numeric = N;

        pub const empty: matrix.hermitian.Sparse(N, uplo, layout) = .{
            .data = &.{},
            .idx = &.{},
            .ptr = &.{},
            .nnz = 0,
            .size = 0,
            .flags = .{ .owns_data = false },
        };

        /// Deinitializes the matrix, freeing any allocated memory and
        /// invalidating it.
        ///
        /// ## Arguments
        /// * `self` (`*matrix.hermitian.Sparse(N, uplo, layout)`): A pointer to
        ///   the matrix to deinitialize.
        /// * `allocator` (`std.mem.Allocator`): The allocator to use for memory
        ///   deallocation. Must be the same allocator used to compile `self`.
        ///
        /// ## Returns
        /// `void`
        pub fn deinit(self: *matrix.hermitian.Sparse(N, uplo, layout), allocator: std.mem.Allocator) void {
            if (self.flags.owns_data) {
                allocator.free(self.data[0..self.nnz]);
                allocator.free(self.idx[0..self.nnz]);
                allocator.free(self.ptr[0 .. self.size + 1]);
            }

            self.* = undefined;
        }

        /// Gets the element at the specified position.
        ///
        /// ## Arguments
        /// * `self` (`matrix.hermitian.Sparse(N, uplo, layout)`): The matrix to
        ///   get the element from.
        /// * `r` (`usize`): The row index of the element to get.
        /// * `c` (`usize`): The column index of the element to get.
        ///
        /// ## Returns
        /// `N`: The element at the specified position.
        ///
        /// ## Errors
        /// * `matrix.Error.PositionOutOfBounds`: If `r` or `c` is out of bounds.
        pub fn get(self: matrix.hermitian.Sparse(N, uplo, layout), r: usize, c: usize) !N {
            if (r >= self.size or c >= self.size)
                return matrix.Error.PositionOutOfBounds;

            var i: usize = r;
            var j: usize = c;
            var noconj: bool = true;
            if (comptime uplo == .upper) {
                if (i > j) {
                    const temp: usize = i;
                    i = j;
                    j = temp;
                    noconj = false;
                }
            } else {
                if (i < j) {
                    const temp: usize = i;
                    i = j;
                    j = temp;
                    noconj = false;
                }
            }

            const major = if (comptime layout == .col_major) j else i;
            const minor = if (comptime layout == .col_major) i else j;

            var left: usize = self.ptr[major];
            var right: usize = self.ptr[major + 1];
            while (left < right) {
                const mid = left + (right - left) / 2;
                const mid_idx = self.idx[mid];

                if (mid_idx == minor) {
                    return if (noconj)
                        self.data[mid]
                    else
                        numeric.conj(self.data[mid]);
                } else if (mid_idx < minor) {
                    left = mid + 1;
                } else {
                    right = mid;
                }
            }

            return numeric.zero(N);
        }

        /// Sets the element at the specified position.
        ///
        /// ## Arguments
        /// * `self` (`*matrix.hermitian.Sparse(N, uplo, layout)`): A pointer to
        ///   the matrix to set the element in.
        /// * `r` (`usize`): The row index of the element to set.
        /// * `c` (`usize`): The column index of the element to set.
        /// * `value` (`N`): The value to set the element to.
        ///
        /// ## Returns
        /// `void`
        ///
        /// ## Errors
        /// * `matrix.Error.PositionOutOfBounds`: If `r` or `c` is out of bounds.
        /// * `matrix.Error.BreaksStructure`: If no existing element is present
        ///   at the specified position.
        pub fn set(self: *matrix.hermitian.Sparse(N, uplo, layout), r: usize, c: usize, value: N) !void {
            if (r >= self.size or c >= self.size)
                return matrix.Error.PositionOutOfBounds;

            var i: usize = r;
            var j: usize = c;
            var noconj: bool = true;
            if (comptime uplo == .upper) {
                if (i > j) {
                    const temp: usize = i;
                    i = j;
                    j = temp;
                    noconj = false;
                }
            } else {
                if (i < j) {
                    const temp: usize = i;
                    i = j;
                    j = temp;
                    noconj = false;
                }
            }

            const major = if (comptime layout == .col_major) j else i;
            const minor = if (comptime layout == .col_major) i else j;

            var left: usize = self.ptr[major];
            var right: usize = self.ptr[major + 1];
            while (left < right) {
                const mid = left + (right - left) / 2;
                const mid_idx = self.idx[mid];

                if (mid_idx == minor) {
                    self.data[mid] = if (noconj)
                        value
                    else
                        numeric.conj(value);
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
