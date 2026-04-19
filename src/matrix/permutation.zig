const std = @import("std");

const meta = @import("../meta.zig");
const Layout = meta.Layout;
const Uplo = meta.Uplo;
const Diag = meta.Diag;

const numeric = @import("../numeric.zig");
const int = @import("../int.zig");

const matrix = @import("../matrix.zig");

const array = @import("../array.zig");

pub const Direction = enum {
    forward,
    backward,
};

/// Permutation matrix type, represented as a contiguous array of `size`
/// elements of type `usize` holding a permutation of `0 .. size`. If
/// `direction` is forward, the element at index `i` indicates the column
/// index of the 1 in row `i`, i.e., if `data[i] = j`, then the element at
/// row `i` and column `j` is 1, and all other elements in row `i` are 0. If
/// `direction` is backward, the same applies but for columns, i.e., if
/// `data[j] = i`, then the element at row `i` and column `j` is 1, and all
/// other elements in column `j` are 0.
pub fn Permutation(N: type) type {
    if (!meta.isNumeric(N))
        @compileError("zsl.matrix.Permutation: N must be a numeric type, got \n\tN = " ++ @typeName(N) ++ "\n");

    return struct {
        data: [*]usize,
        rows: usize,
        cols: usize,
        direction: Direction,
        flags: matrix.Flags,

        // Type signatures
        pub const is_matrix = true;
        pub const is_permutation = true;
        pub const storage_layout = meta.default_layout;
        pub const storage_uplo = meta.default_uplo;
        pub const storage_diag = meta.default_diag;

        // Numeric type
        pub const Numeric = N;

        pub const empty: matrix.Permutation(N) = .{
            .data = &.{},
            .rows = 0,
            .cols = 0,
            .direction = .forward,
            .flags = .{ .owns_data = false },
        };

        /// Initializes a new `matrix.Permutation(N)` with the specified size.
        ///
        /// ## Arguments
        /// * `allocator` (`std.mem.Allocator`): The allocator to use for memory
        ///   allocations.
        /// * `size` (`usize`): The size of the (square) matrix.
        ///
        /// ## Returns
        /// `matrix.Permutation(N)`: The newly initialized matrix.
        ///
        /// ## Errors
        /// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
        /// * `matrix.Error.ZeroDimension`: If `size` is zero.
        pub fn init(allocator: std.mem.Allocator, size: usize) !matrix.Permutation(N) {
            if (size == 0)
                return matrix.Error.ZeroDimension;

            return .{
                .data = (try allocator.alloc(usize, size)).ptr,
                .rows = size,
                .cols = size,
                .direction = .forward,
                .flags = .{ .owns_data = true },
            };
        }

        /// Initializes a new identity `matrix.Permutation(N)` of the specified
        /// size.
        ///
        /// ## Arguments
        /// * `allocator` (`std.mem.Allocator`): The allocator to use for memory
        ///   allocations.
        /// * `size` (`usize`): The size of the (square) matrix.
        ///
        /// ## Returns
        /// `matrix.Permutation(N)`: The newly initialized identity matrix.
        ///
        /// ## Errors
        /// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
        /// * `matrix.Error.ZeroDimension`: If `size` is zero.
        pub fn initIdentity(allocator: std.mem.Allocator, size: usize) !matrix.Permutation(N) {
            const mat: matrix.Permutation(N) = try .init(allocator, size);

            var i: usize = 0;
            while (i < size) : (i += 1) {
                mat.data[i] = i;
            }

            return mat;
        }

        /// Deinitializes the matrix, freeing any allocated memory and
        /// invalidating it.
        ///
        /// ## Arguments
        /// * `self` (`*matrix.Permutation(N)`): A pointer to the matrix to
        ///   deinitialize.
        /// * `allocator` (`std.mem.Allocator`): The allocator to use for memory
        ///   deallocation. Must be the same allocator used to initialize
        ///  `self`.
        ///
        /// ## Returns
        /// `void`
        pub fn deinit(self: *Permutation(N), allocator: std.mem.Allocator) void {
            if (self.flags.owns_data) {
                allocator.free(self.data[0..self.rows]);
            }

            self.* = undefined;
        }

        /// Gets the element at the specified index.
        ///
        /// ## Arguments
        /// * `self` (`matrix.Permutation(N)`): The matrix to get the element
        ///   from.
        /// * `r` (`usize`): The row index of the element to get.
        /// * `c` (`usize`): The column index of the element to get.
        ///
        /// ## Returns
        /// `N`: The element at the specified index.
        ///
        /// ## Errors
        /// * `matrix.Error.PositionOutOfBounds`: If `r` or `c` is out of
        ///   bounds.
        pub fn get(self: matrix.Permutation(N), r: usize, c: usize) !N {
            if (r >= self.rows or c >= self.cols)
                return matrix.Error.PositionOutOfBounds;

            if (self.direction == .forward) {
                if (self.data[r] == c) {
                    return numeric.one(N);
                } else {
                    return numeric.zero(N);
                }
            } else {
                if (self.data[c] == r) {
                    return numeric.one(N);
                } else {
                    return numeric.zero(N);
                }
            }
        }

        /// Gets the element at the specified index without bounds checking.
        ///
        /// ## Arguments
        /// * `self` (`matrix.Permutation(N)`): The matrix to get the element
        ///   from.
        /// * `r` (`usize`): The row index of the element to get. Assumed to be
        ///   within bounds.
        /// * `c` (`usize`): The column index of the element to get. Assumed to
        ///   be within bounds.
        ///
        /// ## Returns
        /// `N`: The element at the specified position.
        pub fn getAssumeInBounds(self: matrix.Permutation(N), r: usize, c: usize) N {
            if (self.direction == .forward) {
                if (self.data[r] == c) {
                    return numeric.one(N);
                } else {
                    return numeric.zero(N);
                }
            } else {
                if (self.data[c] == r) {
                    return numeric.one(N);
                } else {
                    return numeric.zero(N);
                }
            }
        }

        // pub fn set(self: *Permutation(T), row: usize, col: usize, value: usize) !void {
        //     if (row >= self.rows or col >= self.cols)
        //         return matrix.Error.PositionOutOfBounds;

        //     if (value != 0 and value != 1)
        //         return matrix.Error.BreaksStructure;
        // }

        // pub  fn put(self: *Permutation(T), row: usize, col: usize, value: usize) void {
        //     // Unchecked version of set. Assumes row and col are valid and
        //     // in banded range.
        //     if (value == 1) {
        //         self.data[row] = col;
        //     }
        // }

        /// Returns a transposed view of the matrix.
        ///
        /// ## Arguments
        /// * `self` (`matrix.Permutation(N)`): The matrix to transpose.
        ///
        /// ## Returns
        /// `matrix.Permutation(N)`: The transposed matrix.
        pub fn transpose(self: matrix.Permutation(N)) matrix.Permutation(N) {
            return .{
                .data = self.data,
                .rows = self.cols,
                .cols = self.rows,
                .direction = if (self.direction == .forward) .backward else .forward,
                .flags = self.flags,
            };
        }

        /// Copies the matrix to a general dense matrix.
        ///
        /// ## Arguments
        /// * `self` (`matrix.Permutation(N)`): The matrix to copy.
        /// * `allocator` (`std.mem.Allocator`): The allocator to use for memory
        ///   allocations.
        /// * `layout` (`Layout`): The storage layout of the resulting matrix.
        ///
        /// ## Returns
        /// `matrix.general.Dense(N, layout)`: The copied matrix.
        ///
        /// ## Errors
        /// * `std.mem.Allocator.Error.OutOfMemory`: If memory allocation fails.
        pub fn copyToGeneralDenseMatrix(self: matrix.Permutation(N), allocator: std.mem.Allocator, comptime layout: Layout) !matrix.general.Dense(N, layout) {
            const mat: matrix.general.Dense(N, layout) = try .init(allocator, self.rows, self.cols);

            if (comptime layout == .col_major) {
                if (self.direction == .forward) {
                    var j: usize = 0;
                    while (j < self.cols) : (j += 1) {
                        var i: usize = 0;
                        while (i < self.rows) : (i += 1) {
                            mat.data[i + j * mat.ld] = if (self.data[i] == j)
                                numeric.one(N)
                            else
                                numeric.zero(N);
                        }
                    }
                } else {
                    var i: usize = 0;
                    while (i < self.rows) : (i += 1) {
                        var j: usize = 0;
                        while (j < self.cols) : (j += 1) {
                            mat.data[i + j * mat.ld] = if (self.data[j] == i)
                                numeric.one(N)
                            else
                                numeric.zero(N);
                        }
                    }
                }
            } else {
                if (self.direction == .forward) {
                    var i: usize = 0;
                    while (i < self.rows) : (i += 1) {
                        var j: usize = 0;
                        while (j < self.cols) : (j += 1) {
                            mat.data[i * mat.ld + j] = if (self.data[i] == j)
                                numeric.one(N)
                            else
                                numeric.zero(N);
                        }
                    }
                } else {
                    var j: usize = 0;
                    while (j < self.cols) : (j += 1) {
                        var i: usize = 0;
                        while (i < self.rows) : (i += 1) {
                            mat.data[i * mat.ld + j] = if (self.data[j] == i)
                                numeric.one(N)
                            else
                                numeric.zero(N);
                        }
                    }
                }
            }

            return mat;
        }

        // pub fn copyToDenseArray(
        //     self: *const Permutation(N),
        //     allocator: std.mem.Allocator,
        //     comptime order: Order,
        //     ctx: anytype,
        // ) !array.Dense(N, order) {
        //     var result: array.Dense(N, order) = try .init(allocator, &.{ self.rows, self.cols });
        //     errdefer result.deinit(allocator);

        //     if (comptime order == .col_major) {
        //         if (self.direction == .forward) {
        //             var j: usize = 0;
        //             while (j < self.cols) : (j += 1) {
        //                 var i: usize = 0;
        //                 while (i < self.rows) : (i += 1) {
        //                     result.data[i + j * result.strides[0]] = if (self.data[i] == j)
        //                         numeric.one(N, ctx) catch unreachable
        //                     else
        //                         numeric.zero(N, ctx) catch unreachable;
        //                 }
        //             }
        //         } else {
        //             var i: usize = 0;
        //             while (i < self.rows) : (i += 1) {
        //                 var j: usize = 0;
        //                 while (j < self.cols) : (j += 1) {
        //                     result.data[i + j * result.strides[0]] = if (self.data[j] == i)
        //                         numeric.one(N, ctx) catch unreachable
        //                     else
        //                         numeric.zero(N, ctx) catch unreachable;
        //                 }
        //             }
        //         }
        //     } else {
        //         if (self.direction == .forward) {
        //             var i: usize = 0;
        //             while (i < self.rows) : (i += 1) {
        //                 var j: usize = 0;
        //                 while (j < self.cols) : (j += 1) {
        //                     result.data[i * result.strides[0] + j] = if (self.data[i] == j)
        //                         numeric.one(N, ctx) catch unreachable
        //                     else
        //                         numeric.zero(N, ctx) catch unreachable;
        //                 }
        //             }
        //         } else {
        //             var j: usize = 0;
        //             while (j < self.cols) : (j += 1) {
        //                 var i: usize = 0;
        //                 while (i < self.rows) : (i += 1) {
        //                     result.data[i * result.strides[0] + j] = if (self.data[j] == i)
        //                         numeric.one(N, ctx) catch unreachable
        //                     else
        //                         numeric.zero(N, ctx) catch unreachable;
        //                 }
        //             }
        //         }
        //     }

        //     return result;
        // }

        // pub fn submatrix(
        //     self: *const Permutation(T),
        //     start: usize,
        //     end: usize,
        // ) !? {
        //     if (start >= self.rows or end > self.rows or start >= end)
        //         return matrix.Error.InvalidRange;

        //     const sub_size = end - start;

        //     return .{
        //         .data = self.data,
        //         .rows = sub_size,
        //         .cols = sub_size,
        //         .osize = self.osize,
        //         .offset = self.offset + start,
        //         .sdoffset = self.sdoffset,
        //         .flags = .{
        //             .owns_data = false,
        //         },
        //     };
        // }
    };
}
