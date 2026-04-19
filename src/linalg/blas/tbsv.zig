const std = @import("std");

const types = @import("../../types.zig");
const scast = types.scast;
const ops = @import("../../ops.zig");
const constants = @import("../../constants.zig");
const int = @import("../../int.zig");

const linalg = @import("../../linalg.zig");
const blas = @import("../blas.zig");
const Uplo = types.Uplo;
const Diag = types.Diag;
const Order = types.Order;
const Transpose = linalg.Transpose;

/// Solves a system of linear equations whose coefficients are in a triangular
/// band matrix.
///
/// The `tbsv` routine solves one of the following systems of equations:
///
/// ```zig
///     A * x = b,
/// ```
///
/// or
///
/// ```zig
///     conj(A) * x = b,
/// ```
///
/// or
///
/// ```zig
///     A^T * x = b,
/// ```
///
/// or
///
/// ```zig
///     A^H * x = b,
/// ```
///
/// `b` and `x` are `n`-element vectors, `A` is an `n`-by-`n` unit, or non-unit,
/// upper or lower triangular band matrix, with `k + 1` diagonals. The routine
/// does not test for singularity or near-singularity, such tests must be
/// performed before calling this routine.
///
/// Signature
/// ---------
/// ```zig
/// fn tbsv(order: Order, uplo: Uplo, transa: Transpose, diag: Diag, n: i32, k: i32, a: [*]const A, lda: i32, x: [*]X, incx: i32, ctx: anytype) !void
/// ```
///
/// Parameters
/// ----------
/// `order` (`Order`): Specifies whether two-dimensional array storage is
/// row-major or column-major.
///
/// `uplo` (`Uplo`): Specifies whether the matrix `A` is an upper or lower
/// triangular matrix:
/// - If `uplo = upper`, then the matrix is upper triangular.
/// - If `uplo = lower`, then the matrix is lower triangular.
///
/// `transa` (`Transpose`): Specifies the system of equations to be solved:
/// - If `transa = no_trans`, then the system is `A * x = b`.
/// - If `transa = trans`, then the system is `A^T * x = b`.
/// - If `transa = conj_no_trans`, then the system is `conj(A) * x = b`.
/// - If `transa = conj_trans`, then the system is `A^H * x = b`.
///
/// `diag` (`Diag`): Specifies whether the matrix `A` is unit triangular:
/// - If `diag = unit`, then the matrix is unit triangular.
/// - If `diag = non_unit`, then the matrix is non-unit triangular.
///
/// `n` (`i32`): Specifies the order of the matrix `A`. Must be greater than
/// or equal to 0.
///
/// `k` (`i32`): Specifies the number of super-diagonals or sub-diagonals of
/// the matrix `A`. Must be greater than or equal to 0.
///
/// `a` (many-item pointer to `int`, `float`, `cfloat`, `integer`, `rational`,
/// `real`, `complex` or `expression`): Array, size at least `lda * n`.
///
/// `lda` (`i32`): Specifies the leading dimension of `a` as declared in the
/// calling (sub)program. Must be greater than or equal to `k + 1`.
///
/// `x` (mutable many-item pointer to `int`, `float`, `cfloat`, `integer`,
/// `rational`, `real`, `complex` or `expression`): Array, size at least
/// `1 + (n - 1) * abs(incx)`. Before entry, the incremented array `x` must
/// contain the n-element right-hand side vector `b`. On return, it contains the
/// solution vector `x`.
///
/// `incx` (`i32`): Specifies the increment for indexing vector `x`. Must be
/// different from 0.
///
/// Returns
/// -------
/// `void`: The result is stored in `x`.
///
/// Errors
/// ------
/// `linalg.blas.Error.InvalidArgument`: If `n` or `k` are less than 0, if `lda`
/// is less than `k + 1`, or if `incx` is 0.
///
/// Notes
/// -----
/// If the `link_cblas` option is not `null`, the function will try to call the
/// corresponding CBLAS function, if available. In that case, no errors will be
/// raised even if the arguments are invalid.
pub fn tbsv(
    order: Layout,
    uplo: Uplo,
    transa: Transpose,
    diag: Diag,
    n: i32,
    k: i32,
    a: anytype,
    lda: i32,
    x: anytype,
    incx: i32,
    ctx: anytype,
) !void {
    comptime var A: type = @TypeOf(a);
    comptime var X: type = @TypeOf(x);

    comptime if (!types.isManyPointer(A))
        @compileError("zml.linalg.blas.tbsv requires a to be a many-item pointer, got " ++ @typeName(A));

    A = types.Child(A);

    comptime if (!types.isNumeric(A))
        @compileError("zml.linalg.blas.tbsv requires a's child type to numeric, got " ++ @typeName(A));

    comptime if (!types.isManyPointer(X) or types.isConstPointer(X))
        @compileError("zml.linalg.blas.tbsv requires x to be a mutable many-item pointer, got " ++ @typeName(X));

    X = types.Child(X);

    comptime if (!types.isNumeric(X))
        @compileError("zml.linalg.blas.tbsv requires x's child type to be numeric, got " ++ @typeName(X));

    comptime if (A == bool and X == bool)
        @compileError("zml.linalg.blas.tbsv does not support a and x both being bool");

    comptime if (types.isArbitraryPrecision(A) or
        types.isArbitraryPrecision(X))
    {
        // When implemented, expand if
        @compileError("zml.linalg.blas.tbsv not implemented for arbitrary precision types yet");
    } else {
        types.validateContext(@TypeOf(ctx), .{});
    };

    if (comptime A == X and options.link_cblas != null) {
        switch (comptime types.numericType(A)) {
            .float => {
                if (comptime A == f32) {
                    return ci.cblas_stbsv(order.toCUInt(), uplo.toCUInt(), transa.toCUInt(), diag.toCUInt(), scast(c_int, n), scast(c_int, k), a, scast(c_int, lda), x, scast(c_int, incx));
                } else if (comptime A == f64) {
                    return ci.cblas_dtbsv(order.toCUInt(), uplo.toCUInt(), transa.toCUInt(), diag.toCUInt(), scast(c_int, n), scast(c_int, k), a, scast(c_int, lda), x, scast(c_int, incx));
                }
            },
            .cfloat => {
                if (comptime Scalar(A) == f32) {
                    return ci.cblas_ctbsv(order.toCUInt(), uplo.toCUInt(), transa.toCUInt(), diag.toCUInt(), scast(c_int, n), scast(c_int, k), a, scast(c_int, lda), x, scast(c_int, incx));
                } else if (comptime Scalar(A) == f64) {
                    return ci.cblas_ztbsv(order.toCUInt(), uplo.toCUInt(), transa.toCUInt(), diag.toCUInt(), scast(c_int, n), scast(c_int, k), a, scast(c_int, lda), x, scast(c_int, incx));
                }
            },
            else => {},
        }
    }

    return _tbsv(order, uplo, transa, diag, n, k, a, lda, x, incx, ctx);
}

fn _tbsv(
    order: Order,
    uplo: Uplo,
    transa: Transpose,
    diag: Diag,
    n: i32,
    k: i32,
    a: anytype,
    lda: i32,
    x: anytype,
    incx: i32,
    ctx: anytype,
) !void {
    if (order == .col_major) {
        return k_tbsv(
            uplo,
            transa,
            diag,
            n,
            k,
            a,
            lda,
            x,
            incx,
            ctx,
        );
    } else {
        return k_tbsv(
            uplo.invert(),
            transa.invert(),
            diag,
            n,
            k,
            a,
            lda,
            x,
            incx,
            ctx,
        );
    }
}

fn k_tbsv(
    uplo: Uplo,
    transa: Transpose,
    diag: Diag,
    n: i32,
    k: i32,
    a: anytype,
    lda: i32,
    x: anytype,
    incx: i32,
    ctx: anytype,
) !void {
    const A: type = types.Child(@TypeOf(a));
    const X: type = types.Child(@TypeOf(x));
    const C1: type = types.Coerce(A, X);
    const CC: type = types.Coerce(A, X);

    if (n < 0 or k < 0 or lda < (k + 1) or incx == 0)
        return blas.Error.InvalidArgument;

    // Quick return if possible.
    if (n == 0)
        return;

    const noconj: bool = transa == .no_trans or transa == .trans;
    const nounit: bool = diag == .non_unit;

    var kx: i32 = if (incx < 0) (-n + 1) * incx else 0;

    if (comptime !types.isArbitraryPrecision(CC)) {
        if (transa == .no_trans or transa == .conj_no_trans) {
            if (uplo == .upper) {
                if (incx == 1) {
                    var j: i32 = n - 1;
                    while (j >= 0) : (j -= 1) {
                        if (ops.ne(x[scast(u32, j)], 0, ctx) catch unreachable) {
                            const l: i32 = k - j;
                            if (noconj) {
                                if (nounit) {
                                    ops.div_( // x[j] /= a[k + j * lda]
                                        &x[scast(u32, j)],
                                        x[scast(u32, j)],
                                        a[scast(u32, k + j * lda)],
                                        ctx,
                                    ) catch unreachable;
                                }

                                const temp: X = x[scast(u32, j)];

                                var i: i32 = j - 1;
                                while (i >= int.max(0, j - k)) : (i -= 1) {
                                    ops.sub_( // x[i] -= temp * a[l + i + j * lda]
                                        &x[scast(u32, i)],
                                        x[scast(u32, i)],
                                        ops.mul(
                                            temp,
                                            a[scast(u32, l + i + j * lda)],
                                            ctx,
                                        ) catch unreachable,
                                        ctx,
                                    ) catch unreachable;
                                }
                            } else {
                                if (nounit) {
                                    ops.div_( // x[j] /= conj(a[k + j * lda])
                                        &x[scast(u32, j)],
                                        x[scast(u32, j)],
                                        ops.conj(a[scast(u32, k + j * lda)], ctx) catch unreachable,
                                        ctx,
                                    ) catch unreachable;
                                }

                                const temp: X = x[scast(u32, j)];

                                var i: i32 = j - 1;
                                while (i >= int.max(0, j - k)) : (i -= 1) {
                                    ops.sub_( // x[i] -= temp * conj(a[l + i + j * lda])
                                        &x[scast(u32, i)],
                                        x[scast(u32, i)],
                                        ops.mul(
                                            temp,
                                            ops.conj(a[scast(u32, l + i + j * lda)], ctx) catch unreachable,
                                            ctx,
                                        ) catch unreachable,
                                        ctx,
                                    ) catch unreachable;
                                }
                            }
                        }
                    }
                } else {
                    kx += (n - 1) * incx;
                    var jx: i32 = kx;
                    var j: i32 = n - 1;
                    while (j >= 0) : (j -= 1) {
                        kx -= incx;
                        if (ops.ne(x[scast(u32, jx)], 0, ctx) catch unreachable) {
                            var ix: i32 = kx;
                            const l: i32 = k - j;
                            if (noconj) {
                                if (nounit) {
                                    ops.div_( // x[jx] /= a[k + j * lda]
                                        &x[scast(u32, jx)],
                                        x[scast(u32, jx)],
                                        a[scast(u32, k + j * lda)],
                                        ctx,
                                    ) catch unreachable;
                                }

                                const temp: X = x[scast(u32, jx)];

                                var i: i32 = j - 1;
                                while (i >= int.max(0, j - k)) : (i -= 1) {
                                    ops.sub_( // x[ix] -= temp * a[l + i + j * lda]
                                        &x[scast(u32, ix)],
                                        x[scast(u32, ix)],
                                        ops.mul(
                                            temp,
                                            a[scast(u32, l + i + j * lda)],
                                            ctx,
                                        ) catch unreachable,
                                        ctx,
                                    ) catch unreachable;

                                    ix -= incx;
                                }
                            } else {
                                if (nounit) {
                                    ops.div_( // x[jx] /= conj(a[k + j * lda])
                                        &x[scast(u32, jx)],
                                        x[scast(u32, jx)],
                                        ops.conj(a[scast(u32, k + j * lda)], ctx) catch unreachable,
                                        ctx,
                                    ) catch unreachable;
                                }

                                const temp: X = x[scast(u32, jx)];

                                var i: i32 = j - 1;
                                while (i >= int.max(0, j - k)) : (i -= 1) {
                                    ops.sub_( // x[ix] -= temp * conj(a[l + i + j * lda])
                                        &x[scast(u32, ix)],
                                        x[scast(u32, ix)],
                                        ops.mul(
                                            temp,
                                            ops.conj(a[scast(u32, l + i + j * lda)], ctx) catch unreachable,
                                            ctx,
                                        ) catch unreachable,
                                        ctx,
                                    ) catch unreachable;

                                    ix -= incx;
                                }
                            }
                        }

                        jx -= incx;
                    }
                }
            } else {
                if (incx == 1) {
                    var j: i32 = 0;
                    while (j < n) : (j += 1) {
                        if (ops.ne(x[scast(u32, j)], 0, ctx) catch unreachable) {
                            const l: i32 = -j;
                            if (noconj) {
                                if (nounit) {
                                    ops.div_( // x[j] /= a[0 + j * lda]
                                        &x[scast(u32, j)],
                                        x[scast(u32, j)],
                                        a[scast(u32, 0 + j * lda)],
                                        ctx,
                                    ) catch unreachable;
                                }

                                const temp: X = x[scast(u32, j)];

                                var i: i32 = j + 1;
                                while (i < int.min(n, j + k + 1)) : (i += 1) {
                                    ops.sub_( // x[i] -= temp * a[l + i + j * lda]
                                        &x[scast(u32, i)],
                                        x[scast(u32, i)],
                                        ops.mul(
                                            temp,
                                            a[scast(u32, l + i + j * lda)],
                                            ctx,
                                        ) catch unreachable,
                                        ctx,
                                    ) catch unreachable;
                                }
                            } else {
                                if (nounit) {
                                    ops.div_( // x[j] /= conj(a[0 + j * lda])
                                        &x[scast(u32, j)],
                                        x[scast(u32, j)],
                                        ops.conj(a[scast(u32, 0 + j * lda)], ctx) catch unreachable,
                                        ctx,
                                    ) catch unreachable;
                                }

                                const temp: X = x[scast(u32, j)];

                                var i: i32 = j + 1;
                                while (i < int.min(n, j + k + 1)) : (i += 1) {
                                    ops.sub_( // x[i] -= temp * conj(a[l + i + j * lda])
                                        &x[scast(u32, i)],
                                        x[scast(u32, i)],
                                        ops.mul(
                                            temp,
                                            ops.conj(a[scast(u32, l + i + j * lda)], ctx) catch unreachable,
                                            ctx,
                                        ) catch unreachable,
                                        ctx,
                                    ) catch unreachable;
                                }
                            }
                        }
                    }
                } else {
                    var jx: i32 = kx;
                    var j: i32 = 0;
                    while (j < n) : (j += 1) {
                        kx += incx;
                        if (ops.ne(x[scast(u32, jx)], 0, ctx) catch unreachable) {
                            var ix: i32 = kx;
                            const l: i32 = -j;
                            if (noconj) {
                                if (nounit) {
                                    ops.div_( // x[jx] /= a[0 + j * lda]
                                        &x[scast(u32, jx)],
                                        x[scast(u32, jx)],
                                        a[scast(u32, 0 + j * lda)],
                                        ctx,
                                    ) catch unreachable;
                                }

                                const temp: X = x[scast(u32, jx)];

                                var i: i32 = j + 1;
                                while (i < int.min(n, j + k + 1)) : (i += 1) {
                                    ops.sub_( // x[ix] -= temp * a[l + i + j * lda]
                                        &x[scast(u32, ix)],
                                        x[scast(u32, ix)],
                                        ops.mul(
                                            temp,
                                            a[scast(u32, l + i + j * lda)],
                                            ctx,
                                        ) catch unreachable,
                                        ctx,
                                    ) catch unreachable;

                                    ix += incx;
                                }
                            } else {
                                if (nounit) {
                                    ops.div_( // x[jx] /= conj(a[0 + j * lda])
                                        &x[scast(u32, jx)],
                                        x[scast(u32, jx)],
                                        ops.conj(a[scast(u32, 0 + j * lda)], ctx) catch unreachable,
                                        ctx,
                                    ) catch unreachable;
                                }

                                const temp: X = x[scast(u32, jx)];

                                var i: i32 = j + 1;
                                while (i < int.min(n, j + k + 1)) : (i += 1) {
                                    ops.sub_( // x[ix] -= temp * conj(a[l + i + j * lda])
                                        &x[scast(u32, ix)],
                                        x[scast(u32, ix)],
                                        ops.mul(
                                            temp,
                                            ops.conj(a[scast(u32, l + i + j * lda)], ctx) catch unreachable,
                                            ctx,
                                        ) catch unreachable,
                                        ctx,
                                    ) catch unreachable;

                                    ix += incx;
                                }
                            }
                        }

                        jx += incx;
                    }
                }
            }
        } else {
            if (uplo == .upper) {
                if (incx == 1) {
                    var j: i32 = 0;
                    while (j < n) : (j += 1) {
                        var temp: C1 = scast(C1, x[scast(u32, j)]);

                        const l: i32 = k - j;
                        if (noconj) {
                            var i: i32 = int.max(0, j - k);
                            while (i < j) : (i += 1) {
                                ops.sub_( // temp -= a[l + i + j * lda] * x[i]
                                    &temp,
                                    temp,
                                    ops.mul(
                                        a[scast(u32, l + i + j * lda)],
                                        x[scast(u32, i)],
                                        ctx,
                                    ) catch unreachable,
                                    ctx,
                                ) catch unreachable;
                            }

                            if (nounit) {
                                ops.div_( // temp /= a[k + j * lda]
                                    &temp,
                                    temp,
                                    a[scast(u32, k + j * lda)],
                                    ctx,
                                ) catch unreachable;
                            }
                        } else {
                            var i: i32 = int.max(0, j - k);
                            while (i < j) : (i += 1) {
                                ops.sub_( // temp -= conj(a[l + i + j * lda]) * x[i]
                                    &temp,
                                    temp,
                                    ops.mul(
                                        ops.conj(a[scast(u32, l + i + j * lda)], ctx) catch unreachable,
                                        x[scast(u32, i)],
                                        ctx,
                                    ) catch unreachable,
                                    ctx,
                                ) catch unreachable;
                            }

                            if (nounit) {
                                ops.div_( // temp /= conj(a[k + j * lda])
                                    &temp,
                                    temp,
                                    ops.conj(a[scast(u32, k + j * lda)], ctx) catch unreachable,
                                    ctx,
                                ) catch unreachable;
                            }
                        }

                        x[scast(u32, j)] = scast(X, temp);
                    }
                } else {
                    var jx: i32 = kx;
                    var j: i32 = 0;
                    while (j < n) : (j += 1) {
                        var temp: C1 = scast(C1, x[scast(u32, jx)]);

                        var ix: i32 = kx;
                        const l: i32 = k - j;
                        if (noconj) {
                            var i: i32 = int.max(0, j - k);
                            while (i < j) : (i += 1) {
                                ops.sub_( // temp -= a[l + i + j * lda] * x[ix]
                                    &temp,
                                    temp,
                                    ops.mul(
                                        a[scast(u32, l + i + j * lda)],
                                        x[scast(u32, ix)],
                                        ctx,
                                    ) catch unreachable,
                                    ctx,
                                ) catch unreachable;

                                ix += incx;
                            }

                            if (nounit) {
                                ops.div_( // temp /= a[k + j * lda]
                                    &temp,
                                    temp,
                                    a[scast(u32, k + j * lda)],
                                    ctx,
                                ) catch unreachable;
                            }
                        } else {
                            var i: i32 = int.max(0, j - k);
                            while (i < j) : (i += 1) {
                                ops.sub_( // temp -= conj(a[l + i + j * lda]) * x[ix]
                                    &temp,
                                    temp,
                                    ops.mul(
                                        ops.conj(a[scast(u32, l + i + j * lda)], ctx) catch unreachable,
                                        x[scast(u32, ix)],
                                        ctx,
                                    ) catch unreachable,
                                    ctx,
                                ) catch unreachable;

                                ix += incx;
                            }

                            if (nounit) {
                                ops.div_( // temp /= conj(a[k + j * lda])
                                    &temp,
                                    temp,
                                    ops.conj(a[scast(u32, k + j * lda)], ctx) catch unreachable,
                                    ctx,
                                ) catch unreachable;
                            }
                        }

                        x[scast(u32, jx)] = scast(X, temp);

                        jx += incx;

                        if (j >= k) {
                            kx += incx;
                        }
                    }
                }
            } else {
                if (incx == 1) {
                    var j: i32 = n - 1;
                    while (j >= 0) : (j -= 1) {
                        var temp: C1 = scast(C1, x[scast(u32, j)]);

                        const l: i32 = -j;
                        if (noconj) {
                            var i: i32 = int.min(n - 1, j + k);
                            while (i > j) : (i -= 1) {
                                ops.sub_( // temp -= a[l + i + j * lda] * x[i]
                                    &temp,
                                    temp,
                                    ops.mul(
                                        a[scast(u32, l + i + j * lda)],
                                        x[scast(u32, i)],
                                        ctx,
                                    ) catch unreachable,
                                    ctx,
                                ) catch unreachable;
                            }

                            if (nounit) {
                                ops.div_( // temp /= a[0 + j * lda]
                                    &temp,
                                    temp,
                                    a[scast(u32, 0 + j * lda)],
                                    ctx,
                                ) catch unreachable;
                            }
                        } else {
                            var i: i32 = int.min(n - 1, j + k);
                            while (i > j) : (i -= 1) {
                                ops.sub_( // temp -= conj(a[l + i + j * lda]) * x[i]
                                    &temp,
                                    temp,
                                    ops.mul(
                                        ops.conj(a[scast(u32, l + i + j * lda)], ctx) catch unreachable,
                                        x[scast(u32, i)],
                                        ctx,
                                    ) catch unreachable,
                                    ctx,
                                ) catch unreachable;
                            }

                            if (nounit) {
                                ops.div_( // temp /= conj(a[0 + j * lda])
                                    &temp,
                                    temp,
                                    ops.conj(a[scast(u32, 0 + j * lda)], ctx) catch unreachable,
                                    ctx,
                                ) catch unreachable;
                            }
                        }

                        x[scast(u32, j)] = scast(X, temp);
                    }
                } else {
                    kx += (n - 1) * incx;
                    var jx: i32 = kx;
                    var j: i32 = n - 1;
                    while (j >= 0) : (j -= 1) {
                        var temp: C1 = scast(C1, x[scast(u32, jx)]);

                        var ix: i32 = kx;
                        const l: i32 = -j;
                        if (noconj) {
                            var i: i32 = int.min(n - 1, j + k);
                            while (i > j) : (i -= 1) {
                                ops.sub_( // temp -= a[l + i + j * lda] * x[ix]
                                    &temp,
                                    temp,
                                    ops.mul(
                                        a[scast(u32, l + i + j * lda)],
                                        x[scast(u32, ix)],
                                        ctx,
                                    ) catch unreachable,
                                    ctx,
                                ) catch unreachable;

                                ix -= incx;
                            }

                            if (nounit) {
                                ops.div_( // temp /= a[0 + j * lda]
                                    &temp,
                                    temp,
                                    a[scast(u32, 0 + j * lda)],
                                    ctx,
                                ) catch unreachable;
                            }
                        } else {
                            var i: i32 = int.min(n - 1, j + k);
                            while (i > j) : (i -= 1) {
                                ops.sub_( // temp -= conj(a[l + i + j * lda]) * x[ix]
                                    &temp,
                                    temp,
                                    ops.mul(
                                        ops.conj(a[scast(u32, l + i + j * lda)], ctx) catch unreachable,
                                        x[scast(u32, ix)],
                                        ctx,
                                    ) catch unreachable,
                                    ctx,
                                ) catch unreachable;

                                ix -= incx;
                            }

                            if (nounit) {
                                ops.div_( // temp /= conj(a[0 + j * lda])
                                    &temp,
                                    temp,
                                    ops.conj(a[scast(u32, 0 + j * lda)], ctx) catch unreachable,
                                    ctx,
                                ) catch unreachable;
                            }
                        }

                        x[scast(u32, jx)] = scast(X, temp);

                        jx -= incx;

                        if (n - 1 - j >= k) {
                            kx -= incx;
                        }
                    }
                }
            }
        }
    } else {
        // Arbitrary precision types not supported yet
        @compileError("zml.linalg.blas.tbsv not implemented for arbitrary precision types yet");
    }

    return;
}
