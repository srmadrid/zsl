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
/// packed matrix.
///
/// The `tpsv` routine solves one of the following systems of equations:
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
/// where `b` and `x` are `n`-element vectors, `A` is an `n`-by-`n` unit, or
/// non-unit, upper or lower triangular matrix, supplied in packed form.
///
/// Signature
/// ---------
/// ```zig
/// fn tpsv(order: Order, uplo: Uplo, transa: Transpose, diag: Diag, n: i32, ap: [*]const A, x: [*]X, incx: i32, ctx: anytype) !void
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
/// `ap` (many-item pointer to `int`, `float`, `cfloat`, `integer`, `rational`,
/// `real`, `complex` or `expression`): Array, size at least
/// `(n * (n + 1)) / 2`.
///
/// `x` (mutable many-item pointer to `int`, `float`, `cfloat`, `integer`,
/// `rational`, `real`, `complex` or `expression`): Array, size at least
/// `1 + (n - 1) * abs(incx)`. On entry, the incremented array `x` must
/// contain the n-element right-hand side vector `b`. On return, it contains
/// the solution vector `x`.
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
/// `linalg.blas.Error.InvalidArgument`: If `n` is less than 0, or if `incx` is
/// 0.
///
/// Notes
/// -----
/// If the `link_cblas` option is not `null`, the function will try to call the
/// corresponding CBLAS function, if available. In that case, no errors will be
/// raised even if the arguments are invalid.
pub fn tpsv(
    order: Layout,
    uplo: Uplo,
    transa: Transpose,
    diag: Diag,
    n: i32,
    ap: anytype,
    x: anytype,
    incx: i32,
    ctx: anytype,
) !void {
    comptime var A: type = @TypeOf(ap);
    comptime var X: type = @TypeOf(x);

    comptime if (!types.isManyPointer(A))
        @compileError("zml.linalg.blas.tpsv requires ap to be a many-item pointer, got " ++ @typeName(A));

    A = types.Child(A);

    comptime if (!types.isNumeric(A))
        @compileError("zml.linalg.blas.tpsv requires ap's child type to numeric, got " ++ @typeName(A));

    comptime if (!types.isManyPointer(X) or types.isConstPointer(X))
        @compileError("zml.linalg.blas.tpsv requires x to be a mutable many-item pointer, got " ++ @typeName(X));

    X = types.Child(X);

    comptime if (!types.isNumeric(X))
        @compileError("zml.linalg.blas.tpsv requires x's child type to be numeric, got " ++ @typeName(X));

    comptime if (A == bool and X == bool)
        @compileError("zml.linalg.blas.tpsv does not support a and x both being bool");

    comptime if (types.isArbitraryPrecision(A) or
        types.isArbitraryPrecision(X))
    {
        // When implemented, expand if
        @compileError("zml.linalg.blas.tpsv not implemented for arbitrary precision types yet");
    } else {
        types.validateContext(@TypeOf(ctx), .{});
    };

    if (comptime A == X and options.link_cblas != null) {
        switch (comptime types.numericType(A)) {
            .float => {
                if (comptime A == f32) {
                    return ci.cblas_stpsv(order.toCUInt(), uplo.toCUInt(), transa.toCUInt(), diag.toCUInt(), scast(c_int, n), ap, x, scast(c_int, incx));
                } else if (comptime A == f64) {
                    return ci.cblas_dtpsv(order.toCUInt(), uplo.toCUInt(), transa.toCUInt(), diag.toCUInt(), scast(c_int, n), ap, x, scast(c_int, incx));
                }
            },
            .cfloat => {
                if (comptime Scalar(A) == f32) {
                    return ci.cblas_ctpsv(order.toCUInt(), uplo.toCUInt(), transa.toCUInt(), diag.toCUInt(), scast(c_int, n), ap, x, scast(c_int, incx));
                } else if (comptime Scalar(A) == f64) {
                    return ci.cblas_ztpsv(order.toCUInt(), uplo.toCUInt(), transa.toCUInt(), diag.toCUInt(), scast(c_int, n), ap, x, scast(c_int, incx));
                }
            },
            else => {},
        }
    }

    return _tpsv(order, uplo, transa, diag, n, ap, x, incx, ctx);
}

fn _tpsv(
    order: Order,
    uplo: Uplo,
    transa: Transpose,
    diag: Diag,
    n: i32,
    ap: anytype,
    x: anytype,
    incx: i32,
    ctx: anytype,
) !void {
    if (order == .col_major) {
        return k_tpsv(
            uplo,
            transa,
            diag,
            n,
            ap,
            x,
            incx,
            ctx,
        );
    } else {
        return k_tpsv(
            uplo.invert(),
            transa.invert(),
            diag,
            n,
            ap,
            x,
            incx,
            ctx,
        );
    }
}

fn k_tpsv(
    uplo: Uplo,
    transa: Transpose,
    diag: Diag,
    n: i32,
    ap: anytype,
    x: anytype,
    incx: i32,
    ctx: anytype,
) !void {
    const A: type = types.Child(@TypeOf(ap));
    const X: type = types.Child(@TypeOf(x));
    const C1: type = types.Coerce(A, X);
    const CC: type = types.Coerce(A, X);

    if (n < 0 or incx == 0)
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
                var kk: i32 = int.div(n * (n + 1), 2) - 1;
                if (incx == 1) {
                    var j: i32 = n - 1;
                    while (j >= 0) : (j -= 1) {
                        if (ops.ne(x[scast(u32, j)], 0, ctx) catch unreachable) {
                            if (noconj) {
                                if (nounit) {
                                    ops.div_( // x[j] /= ap[kk]
                                        &x[scast(u32, j)],
                                        x[scast(u32, j)],
                                        ap[scast(u32, kk)],
                                        ctx,
                                    ) catch unreachable;
                                }

                                const temp: X = x[scast(u32, j)];

                                var k: i32 = kk - 1;
                                var i: i32 = j - 1;
                                while (i >= 0) : (i -= 1) {
                                    ops.sub_( // x[i] -= temp * ap[k]
                                        &x[scast(u32, i)],
                                        x[scast(u32, i)],
                                        ops.mul(
                                            temp,
                                            ap[scast(u32, k)],
                                            ctx,
                                        ) catch unreachable,
                                        ctx,
                                    ) catch unreachable;

                                    k -= 1;
                                }
                            } else {
                                if (nounit) {
                                    ops.div_( // x[j] /= conj(ap[kk])
                                        &x[scast(u32, j)],
                                        x[scast(u32, j)],
                                        ops.conj(ap[scast(u32, kk)], ctx) catch unreachable,
                                        ctx,
                                    ) catch unreachable;
                                }

                                const temp: X = x[scast(u32, j)];

                                var k: i32 = kk - 1;
                                var i: i32 = j - 1;
                                while (i >= 0) : (i -= 1) {
                                    ops.sub_( // x[i] -= temp * conj(ap[k])
                                        &x[scast(u32, i)],
                                        x[scast(u32, i)],
                                        ops.mul(
                                            temp,
                                            ops.conj(ap[scast(u32, k)], ctx) catch unreachable,
                                            ctx,
                                        ) catch unreachable,
                                        ctx,
                                    ) catch unreachable;

                                    k -= 1;
                                }
                            }
                        }

                        kk -= j + 1;
                    }
                } else {
                    var jx: i32 = kx + (n - 1) * incx;
                    var j: i32 = n - 1;
                    while (j >= 0) : (j -= 1) {
                        if (ops.ne(x[scast(u32, jx)], 0, ctx) catch unreachable) {
                            if (noconj) {
                                if (nounit) {
                                    ops.div_( // x[jx] /= ap[kk]
                                        &x[scast(u32, jx)],
                                        x[scast(u32, jx)],
                                        ap[scast(u32, kk)],
                                        ctx,
                                    ) catch unreachable;
                                }

                                const temp: X = x[scast(u32, jx)];

                                var ix: i32 = jx;
                                var k: i32 = kk - 1;
                                while (k >= kk - j) : (k -= 1) {
                                    ix -= incx;

                                    ops.sub_( // x[ix] -= temp * ap[k]
                                        &x[scast(u32, ix)],
                                        x[scast(u32, ix)],
                                        ops.mul(
                                            temp,
                                            ap[scast(u32, k)],
                                            ctx,
                                        ) catch unreachable,
                                        ctx,
                                    ) catch unreachable;
                                }
                            } else {
                                if (nounit) {
                                    ops.div_( // x[jx] /= conj(ap[kk])
                                        &x[scast(u32, jx)],
                                        x[scast(u32, jx)],
                                        ops.conj(ap[scast(u32, kk)], ctx) catch unreachable,
                                        ctx,
                                    ) catch unreachable;
                                }

                                const temp: X = x[scast(u32, jx)];

                                var ix: i32 = jx;
                                var k: i32 = kk - 1;
                                while (k >= kk - j) : (k -= 1) {
                                    ix -= incx;

                                    ops.sub_( // x[ix] -= temp * conj(ap[k])
                                        &x[scast(u32, ix)],
                                        x[scast(u32, ix)],
                                        ops.mul(
                                            temp,
                                            ops.conj(ap[scast(u32, k)], ctx) catch unreachable,
                                            ctx,
                                        ) catch unreachable,
                                        ctx,
                                    ) catch unreachable;
                                }
                            }
                        }

                        jx -= incx;
                        kk -= j + 1;
                    }
                }
            } else {
                var kk: i32 = 0;
                if (incx == 1) {
                    var j: i32 = 0;
                    while (j < n) : (j += 1) {
                        if (ops.ne(x[scast(u32, j)], 0, ctx) catch unreachable) {
                            if (noconj) {
                                if (nounit) {
                                    ops.div_( // x[j] /= ap[kk]
                                        &x[scast(u32, j)],
                                        x[scast(u32, j)],
                                        ap[scast(u32, kk)],
                                        ctx,
                                    ) catch unreachable;
                                }

                                const temp: X = x[scast(u32, j)];

                                var k: i32 = kk + 1;
                                var i: i32 = j + 1;
                                while (i < n) : (i += 1) {
                                    ops.sub_( // x[i] -= temp * ap[k]
                                        &x[scast(u32, i)],
                                        x[scast(u32, i)],
                                        ops.mul(
                                            temp,
                                            ap[scast(u32, k)],
                                            ctx,
                                        ) catch unreachable,
                                        ctx,
                                    ) catch unreachable;

                                    k += 1;
                                }
                            } else {
                                if (nounit) {
                                    ops.div_( // x[j] /= conj(ap[kk])
                                        &x[scast(u32, j)],
                                        x[scast(u32, j)],
                                        ops.conj(ap[scast(u32, kk)], ctx) catch unreachable,
                                        ctx,
                                    ) catch unreachable;
                                }

                                const temp: X = x[scast(u32, j)];

                                var k: i32 = kk + 1;
                                var i: i32 = j + 1;
                                while (i < n) : (i += 1) {
                                    ops.sub_( // x[i] -= temp * conj(ap[k])
                                        &x[scast(u32, i)],
                                        x[scast(u32, i)],
                                        ops.mul(
                                            temp,
                                            ops.conj(ap[scast(u32, k)], ctx) catch unreachable,
                                            ctx,
                                        ) catch unreachable,
                                        ctx,
                                    ) catch unreachable;

                                    k += 1;
                                }
                            }
                        }

                        kk += n - j;
                    }
                } else {
                    var jx: i32 = kx;
                    var j: i32 = 0;
                    while (j < n) : (j += 1) {
                        if (ops.ne(x[scast(u32, jx)], 0, ctx) catch unreachable) {
                            if (noconj) {
                                if (nounit) {
                                    ops.div_( // x[jx] /= ap[kk]
                                        &x[scast(u32, jx)],
                                        x[scast(u32, jx)],
                                        ap[scast(u32, kk)],
                                        ctx,
                                    ) catch unreachable;
                                }

                                const temp: X = x[scast(u32, jx)];
                                var ix: i32 = jx;
                                var k: i32 = kk + 1;
                                while (k < kk + n - j) : (k += 1) {
                                    ix += incx;

                                    ops.sub_( // x[ix] -= temp * ap[k]
                                        &x[scast(u32, ix)],
                                        x[scast(u32, ix)],
                                        ops.mul(
                                            temp,
                                            ap[scast(u32, k)],
                                            ctx,
                                        ) catch unreachable,
                                        ctx,
                                    ) catch unreachable;
                                }
                            } else {
                                if (nounit) {
                                    ops.div_( // x[jx] /= conj(ap[kk])
                                        &x[scast(u32, jx)],
                                        x[scast(u32, jx)],
                                        ops.conj(ap[scast(u32, kk)], ctx) catch unreachable,
                                        ctx,
                                    ) catch unreachable;
                                }

                                const temp: X = x[scast(u32, jx)];
                                var ix: i32 = jx;
                                var k: i32 = kk + 1;
                                while (k < kk + n - j) : (k += 1) {
                                    ix += incx;

                                    ops.sub_( // x[ix] -= temp * conj(ap[k])
                                        &x[scast(u32, ix)],
                                        x[scast(u32, ix)],
                                        ops.mul(
                                            temp,
                                            ops.conj(ap[scast(u32, k)], ctx) catch unreachable,
                                            ctx,
                                        ) catch unreachable,
                                        ctx,
                                    ) catch unreachable;
                                }
                            }
                        }

                        jx += incx;
                        kk += n - j;
                    }
                }
            }
        } else {
            if (uplo == .upper) {
                var kk: i32 = 0;
                if (incx == 1) {
                    var j: i32 = 0;
                    while (j < n) : (j += 1) {
                        var temp: C1 = scast(C1, x[scast(u32, j)]);

                        if (noconj) {
                            var k: i32 = kk;
                            var i: i32 = 0;
                            while (i < j) : (i += 1) {
                                ops.add_( // temp -= ap[k] * x[i]
                                    &temp,
                                    temp,
                                    ops.mul(
                                        ap[scast(u32, k)],
                                        x[scast(u32, i)],
                                        ctx,
                                    ) catch unreachable,
                                    ctx,
                                ) catch unreachable;

                                k += 1;
                            }

                            if (nounit) {
                                ops.div_( // temp /= ap[kk + j]
                                    &temp,
                                    temp,
                                    ap[scast(u32, kk + j)],
                                    ctx,
                                ) catch unreachable;
                            }
                        } else {
                            var k: i32 = kk;
                            var i: i32 = 0;
                            while (i < j) : (i += 1) {
                                ops.add_( // temp -= conj(ap[k]) * x[i]
                                    &temp,
                                    temp,
                                    ops.mul(
                                        ops.conj(ap[scast(u32, k)], ctx) catch unreachable,
                                        x[scast(u32, i)],
                                        ctx,
                                    ) catch unreachable,
                                    ctx,
                                ) catch unreachable;

                                k += 1;
                            }

                            if (nounit) {
                                ops.div_( // temp /= conj(ap[kk + j])
                                    &temp,
                                    temp,
                                    ops.conj(ap[scast(u32, kk + j)], ctx) catch unreachable,
                                    ctx,
                                ) catch unreachable;
                            }
                        }

                        x[scast(u32, j)] = scast(X, temp);

                        kk += j + 1;
                    }
                } else {
                    var jx: i32 = kx;
                    var j: i32 = 0;
                    while (j < n) : (j += 1) {
                        var temp: C1 = scast(C1, x[scast(u32, jx)]);

                        var ix: i32 = kx;
                        if (noconj) {
                            var k: i32 = kk;
                            while (k < kk + j) : (k += 1) {
                                ops.sub_( // temp -= ap[k] * x[ix]
                                    &temp,
                                    temp,
                                    ops.mul(
                                        ap[scast(u32, k)],
                                        x[scast(u32, ix)],
                                        ctx,
                                    ) catch unreachable,
                                    ctx,
                                ) catch unreachable;

                                ix += incx;
                            }

                            if (nounit) {
                                ops.div_( // temp /= ap[kk + j]
                                    &temp,
                                    temp,
                                    ap[scast(u32, kk + j)],
                                    ctx,
                                ) catch unreachable;
                            }
                        } else {
                            var k: i32 = kk;
                            while (k < kk + j) : (k += 1) {
                                ops.sub_( // temp -= conj(ap[k]) * x[ix]
                                    &temp,
                                    temp,
                                    ops.mul(
                                        ops.conj(ap[scast(u32, k)], ctx) catch unreachable,
                                        x[scast(u32, ix)],
                                        ctx,
                                    ) catch unreachable,
                                    ctx,
                                ) catch unreachable;

                                ix += incx;
                            }

                            if (nounit) {
                                ops.div_( // temp /= conj(ap[kk + j])
                                    &temp,
                                    temp,
                                    ops.conj(ap[scast(u32, kk + j)], ctx) catch unreachable,
                                    ctx,
                                ) catch unreachable;
                            }
                        }

                        x[scast(u32, jx)] = scast(X, temp);

                        jx += incx;
                        kk += j + 1;
                    }
                }
            } else {
                var kk: i32 = int.div(n * (n + 1), 2) - 1;
                if (incx == 1) {
                    var j: i32 = n - 1;
                    while (j >= 0) : (j -= 1) {
                        var temp: C1 = scast(C1, x[scast(u32, j)]);

                        var k: i32 = kk;
                        if (noconj) {
                            var i: i32 = n - 1;
                            while (i > j) : (i -= 1) {
                                ops.sub_( // temp -= ap[k] * x[i]
                                    &temp,
                                    temp,
                                    ops.mul(
                                        ap[scast(u32, k)],
                                        x[scast(u32, i)],
                                        ctx,
                                    ) catch unreachable,
                                    ctx,
                                ) catch unreachable;

                                k -= 1;
                            }

                            if (nounit) {
                                ops.div_( // temp /= ap[kk - (n - 1) + j]
                                    &temp,
                                    temp,
                                    ap[scast(u32, kk - (n - 1) + j)],
                                    ctx,
                                ) catch unreachable;
                            }
                        } else {
                            var i: i32 = n - 1;
                            while (i > j) : (i -= 1) {
                                ops.sub_( // temp -= conj(ap[k]) * x[i]
                                    &temp,
                                    temp,
                                    ops.mul(
                                        ops.conj(ap[scast(u32, k)], ctx) catch unreachable,
                                        x[scast(u32, i)],
                                        ctx,
                                    ) catch unreachable,
                                    ctx,
                                ) catch unreachable;

                                k -= 1;
                            }

                            if (nounit) {
                                ops.div_( // temp /= conj(ap[kk - (n - 1) + j])
                                    &temp,
                                    temp,
                                    ops.conj(ap[scast(u32, kk - (n - 1) + j)], ctx) catch unreachable,
                                    ctx,
                                ) catch unreachable;
                            }
                        }

                        x[scast(u32, j)] = scast(X, temp);

                        kk -= n - j;
                    }
                } else {
                    kx += (n - 1) * incx;
                    var jx: i32 = kx;
                    var j: i32 = n - 1;
                    while (j >= 0) : (j -= 1) {
                        var temp: C1 = scast(C1, x[scast(u32, jx)]);

                        if (noconj) {
                            var ix: i32 = kx;
                            var k: i32 = kk;
                            while (k > kk - (n - (j + 1))) : (k -= 1) {
                                ops.sub_( // temp -= ap[k] * x[ix]
                                    &temp,
                                    temp,
                                    ops.mul(
                                        ap[scast(u32, k)],
                                        x[scast(u32, ix)],
                                        ctx,
                                    ) catch unreachable,
                                    ctx,
                                ) catch unreachable;

                                ix -= incx;
                            }

                            if (nounit) {
                                ops.div_( // temp /= ap[kk - (n - 1) + j]
                                    &temp,
                                    temp,
                                    ap[scast(u32, kk - (n - 1) + j)],
                                    ctx,
                                ) catch unreachable;
                            }
                        } else {
                            var ix: i32 = kx;
                            var k: i32 = kk;
                            while (k > kk - (n - (j + 1))) : (k -= 1) {
                                ops.sub_( // temp -= conj(ap[k] * x[ix])
                                    &temp,
                                    temp,
                                    ops.mul(
                                        ops.conj(ap[scast(u32, k)], ctx) catch unreachable,
                                        x[scast(u32, ix)],
                                        ctx,
                                    ) catch unreachable,
                                    ctx,
                                ) catch unreachable;

                                ix -= incx;
                            }

                            if (nounit) {
                                ops.div_( // temp /= conj(ap[kk - (n - 1) + j])
                                    &temp,
                                    temp,
                                    ops.conj(ap[scast(u32, kk - (n - 1) + j)], ctx) catch unreachable,
                                    ctx,
                                ) catch unreachable;
                            }
                        }

                        x[scast(u32, jx)] = scast(X, temp);

                        jx -= incx;
                        kk -= n - j;
                    }
                }
            }
        }
    } else {
        // Arbitrary precision types not supported yet
        @compileError("zml.linalg.blas.tpsv not implemented for arbitrary precision types yet");
    }

    return;
}
