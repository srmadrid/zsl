const std = @import("std");

const types = @import("../../types.zig");
const scast = types.scast;
const ops = @import("../../ops.zig");
const constants = @import("../../constants.zig");

const linalg = @import("../../linalg.zig");
const blas = @import("../blas.zig");
const Order = types.Order;
const Uplo = types.Uplo;

/// Performs a rank-1 update of a Hermitian packed matrix.
///
/// The `hpr` routine performs a matrix-vector operation defined as:
///
/// ```zig
///     A = alpha * x * conj(x^T) + A,
/// ```
///
/// where `alpha` is a real scalar, `x` is an `n`-element vector, and `A` is an
/// `n`-by-`n` Hermitian matrix, supplied in packed form.
///
/// Signature
/// ---------
/// ```zig
/// fn hpr(order: Order, uplo: Uplo, n: i32, alpha: Al, x: [*]const X, incx: i32, ap: [*]A, ctx: anytype) !void
/// ```
///
/// Parameters
/// ----------
/// `order` (`Order`): Specifies whether two-dimensional array storage is
/// row-major or column-major.
///
///`uplo` (`Uplo`): Specifies whether the upper or lower triangular part of the
/// matrix `A` is supplied in the packed array `ap`:
/// - If `uplo = upper`, then the upper triangular part of the matrix `A` is
/// supplied in `ap`.
/// - If `uplo = lower`, then the lower triangular part of the matrix `A` is
/// supplied in `ap`.
///
/// `n` (`i32`): Specifies the order of the matrix `A`. Must be greater than
/// or equal to 0.
///
/// `alpha` (`bool`, `int`, `float`, `integer`, `rational`, `real` or
/// `expression`): Specifies the scalar `alpha`.
///
/// `x` (many-item pointer to `int`, `float`, `cfloat`, `integer`, `rational`,
/// `real`, `complex` or `expression`): Array, size at least
/// `1 + (n - 1) * abs(incx)`.
///
/// `incx` (`i32`): Specifies the increment for indexing vector `x`. Must be
/// different from 0.
///
/// `ap` (mutable many-item pointer to `int`, `float`, `cfloat`, `integer`,
/// `rational`, `real`, `complex` or `expression`): Array, size at least
/// `(n * (n + 1)) / 2`.
///
/// Returns
/// -------
/// `void`: The result is stored in `a`.
///
/// Errors
/// ------
/// `linalg.blas.Error.InvalidArgument`: If `n` is less than 0, or if `incx` or
/// `incy` are 0.
///
/// Notes
/// -----
/// If the `link_cblas` option is not `null`, the function will try to call the
/// corresponding CBLAS function, if available. In that case, no errors will be
/// raised even if the arguments are invalid.
pub fn hpr(
    order: Layout,
    uplo: Uplo,
    n: i32,
    alpha: anytype,
    x: anytype,
    incx: i32,
    ap: anytype,
    ctx: anytype,
) !void {
    const Al: type = @TypeOf(alpha);
    comptime var X: type = @TypeOf(x);
    comptime var A: type = @TypeOf(ap);

    comptime if (!types.isNumeric(Al))
        @compileError("zml.linalg.blas.hpr requires alpha to be numeric, got " ++ @typeName(Al));

    comptime if (types.isComplex(Al))
        @compileError("zml.linalg.blas.hpr does not support complex alpha, got " ++ @typeName(Al));

    comptime if (!types.isManyPointer(X))
        @compileError("zml.linalg.blas.hpr requires x to be a many-item pointer, got " ++ @typeName(X));

    X = types.Child(X);

    comptime if (!types.isNumeric(X))
        @compileError("zml.linalg.blas.hpr requires x's child type to be numeric, got " ++ @typeName(X));

    comptime if (!types.isManyPointer(A) or types.isConstPointer(A))
        @compileError("zml.linalg.blas.hpr requires a to be a mutable many-item pointer, got " ++ @typeName(A));

    A = types.Child(A);

    comptime if (!types.isNumeric(A))
        @compileError("zml.linalg.blas.hpr requires a's child type to numeric, got " ++ @typeName(A));

    comptime if (Al == bool and X == bool and A == bool)
        @compileError("zml.linalg.blas.hpr does not support alpha, a, x, beta and y all being bool");

    comptime if (types.isArbitraryPrecision(Al) or
        types.isArbitraryPrecision(X) or
        types.isArbitraryPrecision(A))
    {
        // When implemented, expand if
        @compileError("zml.linalg.blas.hpr not implemented for arbitrary precision types yet");
    } else {
        types.validateContext(@TypeOf(ctx), .{});
    };

    if (comptime A == X and types.canCoerce(Al, A) and options.link_cblas != null) {
        switch (comptime types.numericType(A)) {
            .cfloat => {
                if (comptime Scalar(A) == f32) {
                    return ci.cblas_chpr(order.toCUInt(), uplo.toCUInt(), scast(c_int, n), scast(Scalar(A), alpha), x, scast(c_int, incx), ap);
                } else if (comptime Scalar(A) == f64) {
                    return ci.cblas_zhpr(order.toCUInt(), uplo.toCUInt(), scast(c_int, n), scast(Scalar(A), alpha), x, scast(c_int, incx), ap);
                }
            },
            else => {},
        }
    }

    return _hpr(order, uplo, n, alpha, x, incx, ap, ctx);
}

fn _hpr(
    order: Order,
    uplo: Uplo,
    n: i32,
    alpha: anytype,
    x: anytype,
    incx: i32,
    ap: anytype,
    ctx: anytype,
) !void {
    if (order == .col_major) {
        return k_hpr(uplo, n, alpha, x, incx, ap, true, ctx);
    } else {
        return k_hpr(uplo.invert(), n, alpha, x, incx, ap, false, ctx);
    }
}

fn k_hpr(
    uplo: Uplo,
    n: i32,
    alpha: anytype,
    x: anytype,
    incx: i32,
    ap: anytype,
    noconj: bool,
    ctx: anytype,
) !void {
    const Al: type = @TypeOf(alpha);
    const X: type = types.Child(@TypeOf(x));
    const C1: type = types.Coerce(Al, X);
    const A: type = types.Child(@TypeOf(ap));
    const CC: type = types.Coerce(Al, types.Coerce(X, A));

    if (n < 0 or incx == 0)
        return blas.Error.InvalidArgument;

    // Quick return if possible.
    if (n == 0 or ops.eq(alpha, 0, ctx) catch unreachable)
        return;

    const kx: i32 = if (incx < 0) (-n + 1) * incx else 0;

    if (comptime !types.isArbitraryPrecision(CC)) {
        var kk: i32 = 0;
        if (uplo == .upper) {
            if (noconj) {
                if (incx == 1) {
                    var j: i32 = 0;
                    while (j < n) : (j += 1) {
                        if (ops.ne(x[scast(u32, j)], 0, ctx) catch unreachable) {
                            const temp: C1 = ops.mul( // temp = alpha * conj(x[j])
                                ops.conj(x[scast(u32, j)], ctx) catch unreachable,
                                alpha,
                                ctx,
                            ) catch unreachable;

                            var k: i32 = kk;
                            var i: i32 = 0;
                            while (i < j) : (i += 1) {
                                ops.add_( // ap[k] += x[i] * temp
                                    &ap[scast(u32, k)],
                                    ap[scast(u32, k)],
                                    ops.mul(
                                        x[scast(u32, i)],
                                        temp,
                                        ctx,
                                    ) catch unreachable,
                                    ctx,
                                ) catch unreachable;

                                k += 1;
                            }

                            ops.add_( // ap[kk + j] = re(ap[kk + j]) + re(x[j] * temp)
                                &ap[scast(u32, kk + j)],
                                ops.re(ap[scast(u32, kk + j)], ctx) catch unreachable,
                                ops.re(ops.mul(
                                    x[scast(u32, j)],
                                    temp,
                                    ctx,
                                ) catch unreachable, ctx) catch unreachable,
                                ctx,
                            ) catch unreachable;
                        } else {
                            ops.set( // ap[kk + j] = re(ap[kk + j])
                                &ap[scast(u32, kk + j)],
                                ops.re(ap[scast(u32, kk + j)], ctx) catch unreachable,
                                ctx,
                            ) catch unreachable;
                        }

                        kk += j + 1;
                    }
                } else {
                    var jx: i32 = kx;
                    var j: i32 = 0;
                    while (j < n) : (j += 1) {
                        if (ops.ne(x[scast(u32, jx)], 0, ctx) catch unreachable) {
                            const temp: C1 = ops.mul( // temp = alpha * conj(x[jx])
                                ops.conj(x[scast(u32, jx)], ctx) catch unreachable,
                                alpha,
                                ctx,
                            ) catch unreachable;

                            var ix: i32 = kx;
                            var k: i32 = kk;
                            while (k < kk + j) : (k += 1) {
                                ops.add_( // ap[k] += x[ix] * temp
                                    &ap[scast(u32, k)],
                                    ap[scast(u32, k)],
                                    ops.mul(
                                        x[scast(u32, ix)],
                                        temp,
                                        ctx,
                                    ) catch unreachable,
                                    ctx,
                                ) catch unreachable;

                                ix += incx;
                            }

                            ops.add_( // ap[kk + j] = re(ap[kk + j]) + re(x[jx] * temp)
                                &ap[scast(u32, kk + j)],
                                ops.re(ap[scast(u32, kk + j)], ctx) catch unreachable,
                                ops.re(ops.mul(
                                    x[scast(u32, jx)],
                                    temp,
                                    ctx,
                                ) catch unreachable, ctx) catch unreachable,
                                ctx,
                            ) catch unreachable;
                        } else {
                            ops.set( // ap[kk + j] = re(ap[kk + j])
                                &ap[scast(u32, kk + j)],
                                ops.re(ap[scast(u32, kk + j)], ctx) catch unreachable,
                                ctx,
                            ) catch unreachable;
                        }

                        jx += incx;
                        kk += j + 1;
                    }
                }
            } else {
                if (incx == 1) {
                    var j: i32 = 0;
                    while (j < n) : (j += 1) {
                        if (ops.ne(x[scast(u32, j)], 0, ctx) catch unreachable) {
                            const temp: C1 = ops.mul( // temp = alpha * x[j]
                                x[scast(u32, j)],
                                alpha,
                                ctx,
                            ) catch unreachable;

                            var k: i32 = kk;
                            var i: i32 = 0;
                            while (i < j) : (i += 1) {
                                ops.add_( // ap[k] += conj(x[i]) * temp
                                    &ap[scast(u32, k)],
                                    ap[scast(u32, k)],
                                    ops.mul(
                                        ops.conj(x[scast(u32, i)], ctx) catch unreachable,
                                        temp,
                                        ctx,
                                    ) catch unreachable,
                                    ctx,
                                ) catch unreachable;

                                k += 1;
                            }

                            ops.add_( // ap[kk + j] = re(ap[kk + j]) + re(conj(x[j]) * temp)
                                &ap[scast(u32, kk + j)],
                                ops.re(ap[scast(u32, kk + j)], ctx) catch unreachable,
                                ops.re(ops.mul(
                                    ops.conj(x[scast(u32, j)], ctx) catch unreachable,
                                    temp,
                                    ctx,
                                ) catch unreachable, ctx) catch unreachable,
                                ctx,
                            ) catch unreachable;
                        } else {
                            ops.set( // ap[kk + j] = re(ap[kk + j])
                                &ap[scast(u32, kk + j)],
                                ops.re(ap[scast(u32, kk + j)], ctx) catch unreachable,
                                ctx,
                            ) catch unreachable;
                        }

                        kk += j + 1;
                    }
                } else {
                    var jx: i32 = kx;
                    var j: i32 = 0;
                    while (j < n) : (j += 1) {
                        if (ops.ne(x[scast(u32, jx)], 0, ctx) catch unreachable) {
                            const temp: C1 = ops.mul( // temp = alpha * x[jx]
                                x[scast(u32, jx)],
                                alpha,
                                ctx,
                            ) catch unreachable;

                            var ix: i32 = kx;
                            var k: i32 = kk;
                            while (k < kk + j) : (k += 1) {
                                ops.add_( // ap[k] += conj(x[ix]) * temp
                                    &ap[scast(u32, k)],
                                    ap[scast(u32, k)],
                                    ops.mul(
                                        ops.conj(x[scast(u32, ix)], ctx) catch unreachable,
                                        temp,
                                        ctx,
                                    ) catch unreachable,
                                    ctx,
                                ) catch unreachable;

                                ix += incx;
                            }

                            ops.add_( // ap[kk + j] = re(ap[kk + j]) + re(conj(x[jx]) * temp)
                                &ap[scast(u32, kk + j)],
                                ops.re(ap[scast(u32, kk + j)], ctx) catch unreachable,
                                ops.re(ops.mul(
                                    ops.conj(x[scast(u32, jx)], ctx) catch unreachable,
                                    temp,
                                    ctx,
                                ) catch unreachable, ctx) catch unreachable,
                                ctx,
                            ) catch unreachable;
                        } else {
                            ops.set( // ap[kk + j] = re(ap[kk + j])
                                &ap[scast(u32, kk + j)],
                                ops.re(ap[scast(u32, kk + j)], ctx) catch unreachable,
                                ctx,
                            ) catch unreachable;
                        }

                        jx += incx;
                        kk += j + 1;
                    }
                }
            }
        } else {
            if (noconj) {
                if (incx == 1) {
                    var j: i32 = 0;
                    while (j < n) : (j += 1) {
                        if (ops.ne(x[scast(u32, j)], 0, ctx) catch unreachable) {
                            const temp: C1 = ops.mul( // temp = alpha * conj(x[j])
                                ops.conj(x[scast(u32, j)], ctx) catch unreachable,
                                alpha,
                                ctx,
                            ) catch unreachable;

                            ops.add_( // ap[kk] = re(ap[kk]) + re(x[j] * temp)
                                &ap[scast(u32, kk)],
                                ops.re(ap[scast(u32, kk)], ctx) catch unreachable,
                                ops.re(ops.mul(
                                    x[scast(u32, j)],
                                    temp,
                                    ctx,
                                ) catch unreachable, ctx) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            var k: i32 = kk + 1;
                            var i: i32 = j + 1;
                            while (i < n) : (i += 1) {
                                ops.add_( // ap[k] += x[i] * temp
                                    &ap[scast(u32, k)],
                                    ap[scast(u32, k)],
                                    ops.mul(
                                        x[scast(u32, i)],
                                        temp,
                                        ctx,
                                    ) catch unreachable,
                                    ctx,
                                ) catch unreachable;

                                k += 1;
                            }
                        } else {
                            ops.set( // ap[kk] = re(ap[kk])
                                &ap[scast(u32, kk)],
                                ops.re(ap[scast(u32, kk)], ctx) catch unreachable,
                                ctx,
                            ) catch unreachable;
                        }

                        kk += n - j;
                    }
                } else {
                    var jx: i32 = kx;
                    var j: i32 = 0;
                    while (j < n) : (j += 1) {
                        if (ops.ne(x[scast(u32, jx)], 0, ctx) catch unreachable) {
                            const temp: C1 = ops.mul( // temp = alpha * conj(x[jx])
                                ops.conj(x[scast(u32, jx)], ctx) catch unreachable,
                                alpha,
                                ctx,
                            ) catch unreachable;

                            ops.add_( // ap[kk] = re(ap[kk]) + re(x[jx] * temp)
                                &ap[scast(u32, kk)],
                                ops.re(ap[scast(u32, kk)], ctx) catch unreachable,
                                ops.re(ops.mul(
                                    x[scast(u32, jx)],
                                    temp,
                                    ctx,
                                ) catch unreachable, ctx) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            var ix: i32 = jx;
                            var k: i32 = kk + 1;
                            while (k < kk + n - j) : (k += 1) {
                                ix += incx;

                                ops.add_( // ap[k] += x[ix] * temp
                                    &ap[scast(u32, k)],
                                    ap[scast(u32, k)],
                                    ops.mul(
                                        x[scast(u32, ix)],
                                        temp,
                                        ctx,
                                    ) catch unreachable,
                                    ctx,
                                ) catch unreachable;
                            }
                        } else {
                            ops.set( // ap[kk] = re(ap[kk])
                                &ap[scast(u32, kk)],
                                ops.re(ap[scast(u32, kk)], ctx) catch unreachable,
                                ctx,
                            ) catch unreachable;
                        }

                        jx += incx;
                        kk += n - j;
                    }
                }
            } else {
                if (incx == 1) {
                    var j: i32 = 0;
                    while (j < n) : (j += 1) {
                        if (ops.ne(x[scast(u32, j)], 0, ctx) catch unreachable) {
                            const temp: C1 = ops.mul( // temp = alpha * x[j]
                                x[scast(u32, j)],
                                alpha,
                                ctx,
                            ) catch unreachable;

                            ops.add_( // ap[kk] = re(ap[kk]) + re(conj(x[j]) * temp)
                                &ap[scast(u32, kk)],
                                ops.re(ap[scast(u32, kk)], ctx) catch unreachable,
                                ops.re(ops.mul(
                                    ops.conj(x[scast(u32, j)], ctx) catch unreachable,
                                    temp,
                                    ctx,
                                ) catch unreachable, ctx) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            var k: i32 = kk + 1;
                            var i: i32 = j + 1;
                            while (i < n) : (i += 1) {
                                ops.add_( // ap[k] += conj(x[i]) * temp
                                    &ap[scast(u32, k)],
                                    ap[scast(u32, k)],
                                    ops.mul(
                                        ops.conj(x[scast(u32, i)], ctx) catch unreachable,
                                        temp,
                                        ctx,
                                    ) catch unreachable,
                                    ctx,
                                ) catch unreachable;

                                k += 1;
                            }
                        } else {
                            ops.set( // ap[kk] = re(ap[kk])
                                &ap[scast(u32, kk)],
                                ops.re(ap[scast(u32, kk)], ctx) catch unreachable,
                                ctx,
                            ) catch unreachable;
                        }

                        kk += n - j;
                    }
                } else {
                    var jx: i32 = kx;
                    var j: i32 = 0;
                    while (j < n) : (j += 1) {
                        if (ops.ne(x[scast(u32, jx)], 0, ctx) catch unreachable) {
                            const temp: C1 = ops.mul( // temp = alpha * x[jx]
                                x[scast(u32, jx)],
                                alpha,
                                ctx,
                            ) catch unreachable;

                            ops.add_( // ap[kk] = re(ap[kk]) + re(conj(x[jx]) * temp)
                                &ap[scast(u32, kk)],
                                ops.re(ap[scast(u32, kk)], ctx) catch unreachable,
                                ops.re(ops.mul(
                                    ops.conj(x[scast(u32, jx)], ctx) catch unreachable,
                                    temp,
                                    ctx,
                                ) catch unreachable, ctx) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            var ix: i32 = jx;
                            var k: i32 = kk + 1;
                            while (k < kk + n - j) : (k += 1) {
                                ix += incx;

                                ops.add_( // ap[k] += conj(x[ix]) * temp
                                    &ap[scast(u32, k)],
                                    ap[scast(u32, k)],
                                    ops.mul(
                                        ops.conj(x[scast(u32, ix)], ctx) catch unreachable,
                                        temp,
                                        ctx,
                                    ) catch unreachable,
                                    ctx,
                                ) catch unreachable;
                            }
                        } else {
                            ops.set( // ap[kk] = re(ap[kk])
                                &ap[scast(u32, kk)],
                                ops.re(ap[scast(u32, kk)], ctx) catch unreachable,
                                ctx,
                            ) catch unreachable;
                        }

                        jx += incx;
                        kk += n - j;
                    }
                }
            }
        }
    } else {
        // Arbitrary precision types not supported yet
        @compileError("zml.linalg.blas.hpr not implemented for arbitrary precision types yet");
    }

    return;
}
