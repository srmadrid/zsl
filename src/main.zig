const std = @import("std");
const zsl = @import("zsl");
const ci = @cImport({
    @cInclude("lapacke.h");
});

pub fn main() !void {
    // const a: std.mem.Allocator = std.heap.page_allocator;
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var prng = std.Random.DefaultPrng.init(@bitCast(std.time.timestamp()));
    const rand = prng.random();

    var m: usize = 7000;
    _ = &m;
    var n: usize = 8000;
    _ = &n;

    var A = try randomMatrix(zsl.matrix.general.Sparse(f64, .col_major), allocator, rand, m, n);
    defer A.deinit(allocator);
    //printMatrix("A", A);

    var B = try randomMatrix(zsl.matrix.general.Sparse(f64, .col_major), allocator, rand, m, n);
    defer B.deinit(allocator);
    //printMatrix("B", B);

    var C: zsl.matrix.general.Dense(f64, .col_major) = try .init(allocator, m, n);
    defer C.deinit(allocator);

    const start_time = std.time.nanoTimestamp();
    try zsl.matrix.apply2_(&C, A, B, zsl.numeric.add_);
    const end_time = std.time.nanoTimestamp();

    //printMatrix("C", C);

    std.debug.print("zsl.matrix.add_ took {d} seconds on matrices of size {} x {}\n", .{ (zsl.numeric.cast(f128, end_time) - zsl.numeric.cast(f128, start_time)) / 1e9, m, n });
}

fn avg(values: []const f64) f64 {
    var sum: f64 = 0;
    for (values) |value| {
        sum += value;
    }
    return zsl.float.div(sum, values.len);
}

fn avg_complex(values: []const zsl.cf64) f64 {
    var sum: f64 = 0;
    for (values) |value| {
        sum += zsl.cfloat.abs(value);
    }
    return zsl.float.div(sum, values.len);
}

fn random_buffer(
    allocator: std.mem.Allocator,
    size: u32,
) ![]f64 {
    var prng = std.Random.DefaultPrng.init(@bitCast(std.time.timestamp()));
    const rand = prng.random();

    const buffer = try allocator.alloc(f64, size);
    for (0..buffer.len) |i| {
        buffer[i] = rand.float(f64);
    }
    return buffer;
}

fn random_buffer_fill(
    buffer: []f64,
) void {
    var prng = std.Random.DefaultPrng.init(@bitCast(std.time.timestamp()));
    //var prng = std.Random.DefaultPrng.init(2); // fixed seed for reproducibility
    const rand = prng.random();

    for (0..buffer.len) |i| {
        buffer[i] = rand.float(f64);
    }
}

fn random_buffer_fill_complex(
    buffer: []zsl.cf64,
) void {
    //var prng = std.Random.DefaultPrng.init(@bitCast(std.time.timestamp()));
    var prng = std.Random.DefaultPrng.init(2); // fixed seed for reproducibility
    const rand = prng.random();

    for (0..buffer.len) |i| {
        buffer[i] = zsl.cf64.init(rand.float(f64), rand.float(f64));
    }
}

/// Generate a random m×n matrix A with specified 2-norm condition number `kappa`.
pub fn random_matrix(
    allocator: std.mem.Allocator,
    m: u32,
    n: u32,
    kappa: f64,
    order: zsl.Layout,
) ![]f64 {
    // - `allocator`: memory allocator
    // - `m`, `n`: dimensions
    // - `kappa`: desired condition number κ₂(A)
    // - `order`: either .RowMajor or .ColMajor
    //
    // Method:
    // 1. Construct singular values σᵢ geometrically spaced between 1 and κ^(1/min(m,n)).
    // 2. Generate random m×min(m,n) matrix X, QR factor → Q₁ (m×r).
    // 3. Generate random n×min(m,n) matrix Y, QR factor → Q₂ (n×r).
    // 4. Form A = Q₁ * diag(σ) * Q₂ᵀ.
    //     - Compute B = diag(σ) * Q₂ᵀ.
    //     - Then A = Q₁ × B.
    const r = zsl.int.min(m, n);

    // 1) geometric singular values σ[i]
    var sig = try allocator.alloc(f64, r);
    defer allocator.free(sig);
    for (0..r) |i| {
        sig[i] = zsl.float.pow(kappa, zsl.float.div(zsl.scast(f64, i), r - 1));
    }

    // 2) random X: m×r → QR → Q₁
    const X = try random_buffer(allocator, m * r);
    defer allocator.free(X);
    const tauX = try allocator.alloc(f64, r);
    defer allocator.free(tauX);
    _ = ci.LAPACKE_dgeqrf(
        order.toCInt(),
        zsl.scast(c_int, m),
        zsl.scast(c_int, r),
        X.ptr,
        zsl.scast(c_int, if (order == .col_major) m else r),
        tauX.ptr,
    );
    _ = ci.LAPACKE_dorgqr(
        order.toCInt(),
        zsl.scast(c_int, m),
        zsl.scast(c_int, r),
        zsl.scast(c_int, r),
        X.ptr,
        zsl.scast(c_int, if (order == .col_major) m else r),
        tauX.ptr,
    );
    // X now holds Q₁

    // 3) random Y: n×r → QR → Q₂
    const Y = try random_buffer(allocator, n * r);
    defer allocator.free(Y);
    const tauY = try allocator.alloc(f64, r);
    defer allocator.free(tauY);
    _ = ci.LAPACKE_dgeqrf(
        order.toCInt(),
        zsl.scast(c_int, n),
        zsl.scast(c_int, r),
        Y.ptr,
        zsl.scast(c_int, if (order == .col_major) n else r),
        tauY.ptr,
    );
    _ = ci.LAPACKE_dorgqr(
        order.toCInt(),
        zsl.scast(c_int, n),
        zsl.scast(c_int, r),
        zsl.scast(c_int, r),
        Y.ptr,
        zsl.scast(c_int, if (order == .col_major) n else r),
        tauY.ptr,
    );
    // Y now holds Q₂

    // 4a) form B = diag(sig) * Q2ᵀ (B is r×n in same layout)
    const B = try allocator.alloc(f64, r * n);
    defer allocator.free(B);
    for (0..r) |i| {
        const row_start = if (order == .col_major)
            B.ptr + i
        else
            B.ptr + i * n;

        const stride = if (order == .col_major) r else 1;

        for (0..n) |j| {
            // Q2[j,i] is at Y.ptr + j*ldY + i
            const q2ji = (Y.ptr + j * if (order == .col_major) n else r)[i];
            row_start[j * stride] = sig[i] * q2ji;
        }
    }

    // 4b) A = Q1 (m×r) × B (r×n) → A (m×n)
    const A = try allocator.alloc(f64, m * n);
    zsl.linalg.blas.dgemm(
        order,
        .no_trans,
        .no_trans,
        zsl.scast(i32, m),
        zsl.scast(i32, n),
        zsl.scast(i32, r),
        1,
        X.ptr,
        zsl.scast(i32, if (order == .col_major) m else r),
        B.ptr,
        zsl.scast(i32, if (order == .col_major) r else n),
        0,
        A.ptr,
        zsl.scast(i32, if (order == .col_major) m else n),
    );

    return A;
}

pub fn random_matrix_buffer(
    allocator: std.mem.Allocator,
    m: u32,
    n: u32,
    kappa: f64,
    A: []f64,
    order: zsl.Order,
) !void {
    // - `allocator`: memory allocator
    // - `m`, `n`: dimensions
    // - `kappa`: desired condition number κ₂(A)
    // - `order`: either .RowMajor or .ColMajor
    //
    // Method:
    // 1. Construct singular values σᵢ geometrically spaced between 1 and κ^(1/min(m,n)).
    // 2. Generate random m×min(m,n) matrix X, QR factor → Q₁ (m×r).
    // 3. Generate random n×min(m,n) matrix Y, QR factor → Q₂ (n×r).
    // 4. Form A = Q₁ * diag(σ) * Q₂ᵀ.
    //     - Compute B = diag(σ) * Q₂ᵀ.
    //     - Then A = Q₁ × B.
    const r = zsl.int.min(m, n);

    // 1) geometric singular values σ[i]
    var sig = try allocator.alloc(f64, r);
    defer allocator.free(sig);
    for (0..r) |i| {
        sig[i] = zsl.float.pow(kappa, zsl.float.div(zsl.scast(f64, i), r - 1));
    }

    // 2) random X: m×r → QR → Q₁
    const X = try random_buffer(allocator, m * r);
    defer allocator.free(X);
    const tauX = try allocator.alloc(f64, r);
    defer allocator.free(tauX);
    _ = ci.LAPACKE_dgeqrf(
        order.toCInt(),
        zsl.scast(c_int, m),
        zsl.scast(c_int, r),
        X.ptr,
        zsl.scast(c_int, if (order == .col_major) m else r),
        tauX.ptr,
    );
    _ = ci.LAPACKE_dorgqr(
        order.toCInt(),
        zsl.scast(c_int, m),
        zsl.scast(c_int, r),
        zsl.scast(c_int, r),
        X.ptr,
        zsl.scast(c_int, if (order == .col_major) m else r),
        tauX.ptr,
    );
    // X now holds Q₁

    // 3) random Y: n×r → QR → Q₂
    const Y = try random_buffer(allocator, n * r);
    defer allocator.free(Y);
    const tauY = try allocator.alloc(f64, r);
    defer allocator.free(tauY);
    _ = ci.LAPACKE_dgeqrf(
        order.toCInt(),
        zsl.scast(c_int, n),
        zsl.scast(c_int, r),
        Y.ptr,
        zsl.scast(c_int, if (order == .col_major) n else r),
        tauY.ptr,
    );
    _ = ci.LAPACKE_dorgqr(
        order.toCInt(),
        zsl.scast(c_int, n),
        zsl.scast(c_int, r),
        zsl.scast(c_int, r),
        Y.ptr,
        zsl.scast(c_int, if (order == .col_major) n else r),
        tauY.ptr,
    );
    // Y now holds Q₂

    // 4a) form B = diag(sig) * Q2ᵀ (B is r×n in same layout)
    const B = try allocator.alloc(f64, r * n);
    defer allocator.free(B);
    for (0..r) |i| {
        const row_start = if (order == .col_major)
            B.ptr + i
        else
            B.ptr + i * n;

        const stride = if (order == .col_major) r else 1;

        for (0..n) |j| {
            // Q2[j,i] is at Y.ptr + j*ldY + i
            const q2ji = (Y.ptr + j * if (order == .col_major) n else r)[i];
            row_start[j * stride] = sig[i] * q2ji;
        }
    }

    // 4b) A = Q1 (m×r) × B (r×n) → A (m×n)
    zsl.linalg.blas.dgemm(
        order,
        .no_trans,
        .no_trans,
        zsl.scast(i32, m),
        zsl.scast(i32, n),
        zsl.scast(i32, r),
        1,
        X.ptr,
        zsl.scast(i32, if (order == .col_major) m else r),
        B.ptr,
        zsl.scast(i32, if (order == .col_major) r else n),
        0,
        A.ptr,
        zsl.scast(i32, if (order == .col_major) m else n),
    );
}

fn max_difference(a: []const f64, b: []const f64) struct {
    index: u32,
    value: f64,
} {
    std.debug.assert(a.len == b.len);

    var max_diff: f64 = 0;
    var max_index: u32 = 0;

    var i: u32 = 0;
    while (i < a.len) : (i += 1) {
        const diff = zsl.float.abs(a[i] - b[i]);
        if (diff > max_diff) {
            max_diff = diff;
            max_index = i;
        }
    }

    return .{ .index = max_index, .value = max_diff };
}

fn random_symmetric_matrix(
    allocator: std.mem.Allocator,
    size: u32,
    factor: f64,
) ![]f64 {
    var prng = std.Random.DefaultPrng.init(@bitCast(std.time.timestamp()));
    const rand = prng.random();

    const matrix = try allocator.alloc(f64, size * size);

    for (0..size) |i| {
        for (i + 1..size) |j| {
            const value = rand.float(f64) * factor;
            matrix[i * size + j] = value;
            matrix[j * size + i] = value;
        }
    }

    return matrix;
}

/// Generates a random symmetric positive definite matrix with a specified condition number.
fn random_symmetric_positive_definite_matrix(
    allocator: std.mem.Allocator,
    size: u32,
    cond_target: f64,
) ![]f64 {
    // 1) compute λ_i geometrically between 1 and cond_target
    var lambdas = try allocator.alloc(f64, size);
    defer allocator.free(lambdas);
    const l_min = 1;
    const l_max = cond_target;
    for (0..size) |i| {
        lambdas[i] = l_min * zsl.float.pow(l_max / l_min, zsl.float.div(zsl.scast(f64, i), size - 1));
    }

    // 2) random X, then QR -> get Q (n×n)
    const X = try random_buffer(allocator, size * size);
    defer allocator.free(X);
    const tau = try allocator.alloc(f64, size);
    defer allocator.free(tau);
    // QR factorization in-place: X = Q*R
    _ = ci.LAPACKE_dgeqrf(
        zsl.Order.col_major.toCInt(),
        zsl.scast(c_int, size),
        zsl.scast(c_int, size),
        X.ptr,
        zsl.scast(c_int, size),
        tau.ptr,
    );
    _ = ci.LAPACKE_dorgqr(
        zsl.Order.col_major.toCInt(),
        zsl.scast(c_int, size),
        zsl.scast(c_int, size),
        zsl.scast(c_int, size),
        X.ptr,
        zsl.scast(c_int, size),
        tau.ptr,
    );
    // now X holds Q

    // 3) form B = D * Q^T, where D = diag(λ_1, λ_2, ..., λ_n)
    var B = try allocator.alloc(f64, size * size);
    defer allocator.free(B);
    // copy Q^T into B
    for (0..size) |i| {
        for (0..size) |j|
            B[i * size + j] = X[j * size + i];
    }
    // scale row i of B by λ_i
    for (0..size) |i| {
        zsl.linalg.blas.dscal(zsl.scast(i32, size), lambdas[i], B.ptr + i * size, 1);
    }

    // 4) Assemble A = Q * D * Q^T as A = Q * B
    const A = try allocator.alloc(f64, size * size);
    zsl.linalg.blas.dgemm(
        .col_major,
        .no_trans,
        .no_trans,
        zsl.scast(i32, size),
        zsl.scast(i32, size),
        zsl.scast(i32, size),
        1,
        X.ptr,
        zsl.scast(i32, size),
        B.ptr,
        zsl.scast(i32, size),
        0,
        A.ptr,
        zsl.scast(i32, size),
    );

    return A;
}

fn frobernius_norm_difference(a: []const f64, b: []const f64) f64 {
    std.debug.assert(a.len == b.len);

    var norm: f64 = 0;
    for (0..a.len) |i| {
        const diff = a[i] - b[i];
        norm += diff * diff;
    }
    return zsl.float.sqrt(norm);
}

fn frobernius_norm_difference_matrix(a: anytype, b: anytype) !f64 {
    const m = if (comptime zsl.types.isSymmetricMatrix(@TypeOf(a)) or
        zsl.types.isHermitianMatrix(@TypeOf(a)) or
        zsl.types.isTridiagonalMatrix(@TypeOf(a)) or
        zsl.types.isPermutationMatrix(@TypeOf(a)))
        a.size
    else
        a.rows;
    const n = if (comptime zsl.types.isSymmetricMatrix(@TypeOf(a)) or
        zsl.types.isHermitianMatrix(@TypeOf(a)) or
        zsl.types.isTridiagonalMatrix(@TypeOf(a)) or
        zsl.types.isPermutationMatrix(@TypeOf(a)))
        a.size
    else
        a.cols;

    var norm: f64 = 0;

    var i: u32 = 0;
    while (i < m) : (i += 1) {
        var j: u32 = 0;
        while (j < n) : (j += 1) {
            if (comptime !zsl.types.isComplex(zsl.types.Numeric(@TypeOf(a))) and !zsl.types.isComplex(zsl.types.Numeric(@TypeOf(b)))) {
                const diff = try a.get(i, j) - try b.get(i, j);
                norm += diff * diff;
            } else {
                const diff = try zsl.sub(try a.get(i, j), try b.get(i, j), .{});
                norm += try zsl.abs2(diff, .{});
            }
        }
    }

    return zsl.float.sqrt(norm);
}

fn is_symmetric(a: []const f64, size: u32) bool {
    for (0..size) |i| {
        for (i + 1..size) |j| {
            if (!std.math.approxEqRel(f64, a[i * size + j], a[j * size + i], 1e-9)) {
                return false;
            }
        }
    }
    return true;
}

fn random_complex_matrix(
    allocator: std.mem.Allocator,
    rows: u32,
    cols: u32,
    factor: f64,
) ![]zsl.cf64 {
    var prng = std.Random.DefaultPrng.init(@bitCast(std.time.timestamp()));
    const rand = prng.random();

    const matrix = try allocator.alloc(zsl.cf64, rows * cols);
    for (0..matrix.len) |i| {
        matrix[i] = zsl.cf64.init(rand.float(f64) * factor, rand.float(f64) * factor);
    }
    return matrix;
}

fn random_complex_hermitian_positive_definite_matrix(
    allocator: std.mem.Allocator,
    size: u32,
    factor: f64,
) ![]zsl.cf64 {
    // allocate M
    const M = try random_complex_matrix(allocator, size, size, factor);
    // allocate A = M M^H
    const A = try allocator.alloc(zsl.cf64, size * size);

    // A = M × M^H
    zsl.linalg.blas.zgemm(
        .row_major,
        .no_trans,
        .conj_trans,
        zsl.scast(i32, size),
        zsl.scast(i32, size),
        zsl.scast(i32, size),
        zsl.cf64.init(1, 0),
        M.ptr,
        zsl.scast(i32, size),
        M.ptr,
        zsl.scast(i32, size),
        zsl.cf64.init(0, 0),
        A.ptr,
        zsl.scast(i32, size),
    );

    allocator.free(M);
    return A;
}

fn frobenius_norm_complex_difference(a: []const zsl.cf64, b: []const zsl.cf64) f64 {
    std.debug.assert(a.len == b.len);

    var norm: f64 = 0;
    for (0..a.len) |i| {
        const diff = zsl.cfloat.sub(a[i], b[i]);
        norm += diff.re * diff.re + diff.im * diff.im;
    }
    return zsl.float.sqrt(norm);
}

fn is_hermitian(a: []const zsl.cf64, size: u32) bool {
    for (0..size) |i| {
        for (i + 1..size) |j| {
            if (!std.math.approxEqRel(f64, a[i * size + j].re, a[j * size + i].re, 1e-9) or
                !std.math.approxEqRel(f64, a[i * size + j].im, -a[j * size + i].im, 1e-9))
            {
                return false;
            }
        }
    }
    return true;
}

fn print_complex_matrix(desc: []const u8, m: u32, n: u32, a: []zsl.cf64, lda: u32, order: zsl.Order) void {
    std.debug.print("\n{s}\n", .{desc});
    if (order == .row_major) {
        var i: u32 = 0;
        while (i < m) : (i += 1) {
            var j: u32 = 0;
            while (j < n) : (j += 1) {
                std.debug.print("{d:.4} + {d:.4}i  ", .{ a[i * lda + j].re, a[i * lda + j].im });
            }
            std.debug.print("\n", .{});
        }
    } else {
        var i: u32 = 0;
        while (i < m) : (i += 1) {
            var j: u32 = 0;
            while (j < n) : (j += 1) {
                std.debug.print("{d:.4} + {d:.4}i  ", .{ a[i + j * lda].re, a[i + j * lda].im });
            }
            std.debug.print("\n", .{});
        }
    }
}

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

fn randomMatrix(comptime M: type, allocator: std.mem.Allocator, rand: std.Random, rows: usize, cols: usize) !M {
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
            const nnz: usize = (rows * cols) / 100;

            var builder: zsl.matrix.builder.Sparse(zsl.types.Numeric(M)) = try .init(allocator, rows, cols, nnz);
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

            return try builder.compile(allocator, zsl.types.layoutOf(M));
        },
        .symmetric_sparse, .hermitian_sparse => {
            const nnz: usize = rows;

            var builder: zsl.matrix.builder.Sparse(zsl.types.Numeric(M)) = try .init(allocator, rows, rows, nnz);
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
                builder.compileSymmetric(allocator, zsl.types.uploOf(M), zsl.types.layoutOf(M))
            else
                builder.compileHermitian(allocator, zsl.types.uploOf(M), zsl.types.layoutOf(M));
        },
        .triangular_sparse => {
            const nnz: usize = zsl.int.max(rows, cols);

            var builder: zsl.matrix.builder.Sparse(zsl.types.Numeric(M)) = try .init(allocator, rows, cols, nnz);
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

            return builder.compileTriangular(allocator, zsl.types.uploOf(M), zsl.types.diagOf(M), zsl.types.layoutOf(M));
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

fn printMatrix(desc: []const u8, A: anytype) void {
    std.debug.print("\nMatrix {s}:\n\n", .{desc});

    const rows = if (comptime zsl.types.isSquareMatrix(@TypeOf(A)))
        A.size
    else
        A.rows;
    const cols = if (comptime zsl.types.isSquareMatrix(@TypeOf(A)))
        A.size
    else
        A.cols;

    var i: u32 = 0;
    while (i < rows) : (i += 1) {
        std.debug.print("\t", .{});

        var j: u32 = 0;
        while (j < cols) : (j += 1) {
            if (comptime zsl.types.isComplex(zsl.types.Numeric(@TypeOf(A)))) {
                std.debug.print("{d:7.4} + {d:7.4}i    ", .{ (A.get(i, j) catch unreachable).re, (A.get(i, j) catch unreachable).im });
            } else {
                std.debug.print("{d:5.4}    ", .{A.get(i, j) catch unreachable});
            }
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("\n", .{});
}

fn randomVector(comptime V: type, allocator: std.mem.Allocator, rand: std.Random, len: usize) !V {
    switch (comptime zsl.types.vectorType(V)) {
        .dense => {
            var result: V = try .init(allocator, len);

            var i: usize = 0;
            while (i < len) : (i += 1) {
                result.set(
                    i,
                    zsl.numeric.cast(
                        zsl.types.Numeric(V),
                        if (comptime zsl.types.isComplex(zsl.types.Numeric(V)))
                            zsl.cf64{ .re = rand.float(f64), .im = rand.float(f64) }
                        else
                            rand.float(f64),
                    ),
                ) catch unreachable;
            }

            return result;
        },
        .sparse => {
            const nnz: usize = zsl.int.max(1, rand.intRangeAtMost(usize, len / 10, len / 2));

            var result: V = try .init(allocator, len, nnz);
            errdefer result.deinit(allocator);

            // generate random indices
            var used: std.AutoHashMap(usize, void) = .init(allocator);
            defer used.deinit();
            var count: usize = 0;
            while (count < nnz) : (count += 1) {
                const i = rand.intRangeAtMost(usize, 0, len - 1);
                if (!used.contains(i)) {
                    try used.put(i, {});
                    try result.set(
                        allocator,
                        i,
                        zsl.numeric.cast(
                            zsl.types.Numeric(V),
                            if (comptime zsl.types.isComplex(zsl.types.Numeric(V)))
                                zsl.cf64{ .re = rand.float(f64), .im = rand.float(f64) }
                            else
                                rand.float(f64),
                        ),
                    );
                } else {
                    count -= 1; // try again
                }
            }

            return result;
        },
        else => unreachable,
    }
}

fn printVector(desc: []const u8, v: anytype) void {
    std.debug.print("\nVector {s}:\n", .{desc});

    var i: usize = 0;
    while (i < v.len) : (i += 1) {
        if (comptime zsl.types.isComplex(zsl.types.Numeric(@TypeOf(v)))) {
            std.debug.print("{d:7.4} + {d:7.4}i\n", .{ (v.get(i) catch unreachable).re, (v.get(i) catch unreachable).im });
        } else {
            std.debug.print("{d:5.4}\n", .{v.get(i) catch unreachable});
        }
    }
    std.debug.print("\n", .{});
}
