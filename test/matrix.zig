const std = @import("std");

const zsl = @import("zsl");

fn randomPermutation(rand: std.Random, data: []usize) void {
    // Initialize with identity permutation
    var i: usize = 0;
    while (i < data.len) : (i += 1) {
        data[i] = i;
    }

    // Shuffle using Fisher-Yates algorithm
    i = data.len - 1;
    while (i > 0) : (i -= 1) {
        const j = rand.intRangeAtMost(usize, 0, i);
        const temp = data[i];
        data[i] = data[j];
        data[j] = temp;
    }
}

pub fn randomMatrix(comptime M: type, allocator: std.mem.Allocator, rand: std.Random, rows: usize, cols: usize) !M {
    switch (comptime zsl.types.matrixType(M)) {
        .general_dense => {
            var result: M = try .init(allocator, rows, cols);

            var i: usize = 0;
            while (i < rows) : (i += 1) {
                var j: usize = 0;
                while (j < cols) : (j += 1) {
                    result.set(
                        i,
                        j,
                        zsl.numeric.cast(
                            zsl.types.Numeric(M),
                            if (comptime zsl.types.isComplex(zsl.types.Numeric(M)))
                                zsl.cf64{ .re = rand.float(f64), .im = rand.float(f64) }
                            else
                                rand.float(f64),
                        ),
                    ) catch unreachable;
                }
            }

            return result;
        },
        .symmetric_dense, .hermitian_dense => {
            var result: M = try .init(allocator, rows);

            var i: usize = 0;
            while (i < rows) : (i += 1) {
                var j: usize = i;
                while (j < rows) : (j += 1) {
                    result.set(
                        i,
                        j,
                        zsl.numeric.cast(
                            zsl.types.Numeric(M),
                            if (comptime zsl.types.isComplex(zsl.types.Numeric(M)))
                                zsl.cf64{ .re = rand.float(f64), .im = if ((comptime zsl.types.isHermitianMatrix(M)) and i == j) 0.0 else rand.float(f64) }
                            else
                                rand.float(f64),
                        ),
                    ) catch unreachable;
                }
            }

            return result;
        },
        .triangular_dense => {
            var result: M = try M.init(allocator, rows, cols);

            if (comptime zsl.types.uploOf(M) == .upper) {
                var i: usize = 0;
                while (i < zsl.int.min(rows, cols)) : (i += 1) {
                    if (comptime zsl.types.diagOf(M) == .non_unit) {
                        result.set(
                            i,
                            i,
                            zsl.numeric.cast(
                                zsl.types.Numeric(M),
                                if (comptime zsl.types.isComplex(zsl.types.Numeric(M)))
                                    zsl.cf64{ .re = rand.float(f64), .im = rand.float(f64) }
                                else
                                    rand.float(f64),
                            ),
                        ) catch unreachable;
                    }

                    var j: usize = i + 1;
                    while (j < cols) : (j += 1) {
                        result.set(
                            i,
                            j,
                            zsl.numeric.cast(
                                zsl.types.Numeric(M),
                                if (comptime zsl.types.isComplex(zsl.types.Numeric(M)))
                                    zsl.cf64{ .re = rand.float(f64), .im = rand.float(f64) }
                                else
                                    rand.float(f64),
                            ),
                        ) catch unreachable;
                    }
                }
            } else {
                var i: usize = 0;
                while (i < rows) : (i += 1) {
                    var j: usize = 0;
                    while (j < i and j < cols) : (j += 1) {
                        result.set(
                            i,
                            j,
                            zsl.numeric.cast(
                                zsl.types.Numeric(M),
                                if (comptime zsl.types.isComplex(zsl.types.Numeric(M)))
                                    zsl.cf64{ .re = rand.float(f64), .im = rand.float(f64) }
                                else
                                    rand.float(f64),
                            ),
                        ) catch unreachable;
                    }

                    if ((comptime zsl.types.diagOf(M) == .non_unit) and i < cols) {
                        result.set(
                            i,
                            i,
                            zsl.numeric.cast(
                                zsl.types.Numeric(M),
                                if (comptime zsl.types.isComplex(zsl.types.Numeric(M)))
                                    zsl.cf64{ .re = rand.float(f64), .im = rand.float(f64) }
                                else
                                    rand.float(f64),
                            ),
                        ) catch unreachable;
                    }
                }
            }

            return result;
        },
        .general_sparse => {
            const nnz: usize = zsl.int.max(rows, cols);

            var builder: zsl.matrix.builder.Sparse(zsl.types.Numeric(M), zsl.types.layoutOf(M)) = try .init(allocator, rows, cols, nnz);
            errdefer builder.deinit(allocator);

            var count: usize = 0;
            while (count < nnz) : (count += 1) {
                builder.appendAssumeCapacity(
                    rand.intRangeAtMost(usize, 0, rows - 1),
                    rand.intRangeAtMost(usize, 0, cols - 1),
                    zsl.numeric.cast(
                        zsl.types.Numeric(M),
                        if (comptime zsl.types.isComplex(zsl.types.Numeric(M)))
                            zsl.cf64{ .re = rand.float(f64), .im = rand.float(f64) }
                        else
                            rand.float(f64),
                    ),
                );
            }

            return try builder.compile(allocator);
        },
        .symmetric_sparse, .hermitian_sparse => {
            const nnz: usize = rows;

            var builder: zsl.matrix.builder.Sparse(zsl.types.Numeric(M), zsl.types.layoutOf(M)) = try .init(allocator, rows, rows, nnz);
            errdefer builder.deinit(allocator);

            var count: usize = 0;
            while (count < nnz) : (count += 1) {
                const r = rand.intRangeAtMost(usize, 0, rows - 1);
                const c = rand.intRangeAtMost(usize, 0, cols - 1);

                builder.appendAssumeCapacity(
                    r,
                    c,
                    zsl.numeric.cast(
                        zsl.types.Numeric(M),
                        if (comptime zsl.types.isComplex(zsl.types.Numeric(M)))
                            zsl.cf64{ .re = rand.float(f64), .im = if ((comptime zsl.types.isHermitianMatrix(M)) and r == c) 0.0 else rand.float(f64) }
                        else
                            rand.float(f64),
                    ),
                );
            }

            return if (comptime zsl.types.isSymmetricSparseMatrix(M))
                builder.compileSymmetric(allocator, zsl.types.uploOf(M))
            else
                builder.compileHermitian(allocator, zsl.types.uploOf(M));
        },
        .triangular_sparse => {
            const nnz: usize = zsl.int.max(rows, cols);

            var builder: zsl.matrix.builder.Sparse(zsl.types.Numeric(M), zsl.types.layoutOf(M)) = try .init(allocator, rows, cols, nnz);
            errdefer builder.deinit(allocator);

            var count: usize = 0;
            while (count < nnz) : (count += 1) {
                const r = rand.intRangeAtMost(usize, 0, rows - 1);
                const c = rand.intRangeAtMost(usize, 0, cols - 1);

                builder.appendAssumeCapacity(
                    r,
                    c,
                    zsl.numeric.cast(
                        zsl.types.Numeric(M),
                        if (comptime zsl.types.isComplex(zsl.types.Numeric(M)))
                            zsl.cf64{ .re = rand.float(f64), .im = rand.float(f64) }
                        else
                            rand.float(f64),
                    ),
                );
            }

            return builder.compileTriangular(allocator, zsl.types.uploOf(M), zsl.types.diagOf(M));
        },
        .diagonal => {
            var result: M = try .init(allocator, rows, cols);
            errdefer result.deinit(allocator);

            var i: usize = 0;
            while (i < zsl.int.min(rows, cols)) : (i += 1) {
                result.set(
                    i,
                    i,
                    zsl.numeric.cast(
                        zsl.types.Numeric(M),
                        if (comptime zsl.types.isComplex(zsl.types.Numeric(M)))
                            zsl.cf64{ .re = rand.float(f64), .im = rand.float(f64) }
                        else
                            rand.float(f64),
                    ),
                ) catch unreachable;
            }

            return result;
        },
        .permutation => {
            var result: M = try .init(allocator, rows);
            errdefer result.deinit(allocator);

            randomPermutation(rand, result.data[0..rows]);

            return result;
        },
        else => unreachable,
    }
}

pub fn correctApply2(allocator: std.mem.Allocator, m: usize, n: usize, A: anytype, B: anytype, op: anytype) !zsl.matrix.general.Dense(zsl.cf64, .col_major) {
    const result: zsl.matrix.general.Dense(zsl.cf64, .col_major) = try .init(allocator, m, n);

    var j: usize = 0;
    while (j < result.cols) : (j += 1) {
        var i: usize = 0;
        while (i < result.rows) : (i += 1) {
            result.data[result._index(i, j)] = zsl.numeric.cast(
                zsl.cf64,
                op(
                    if (comptime zsl.types.isMatrix(@TypeOf(A))) A.get(i, j) catch unreachable else A,
                    if (comptime zsl.types.isMatrix(@TypeOf(B))) B.get(i, j) catch unreachable else B,
                ),
            );
        }
    }

    return result;
}

pub fn areEql(A: anytype, B: anytype) !void {
    var all_eql = true;

    var j: usize = 0;
    while (j < B.cols) : (j += 1) {
        var i: usize = 0;
        while (i < B.rows) : (i += 1) {
            all_eql = all_eql and zsl.numeric.eq(A.get(i, j) catch unreachable, B.get(i, j) catch unreachable);
        }
    }

    if (!all_eql)
        return error.NotEqual;
}

test {
    _ = @import("matrix/apply2_.zig");
}
