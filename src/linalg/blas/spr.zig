const std = @import("std");

const types = @import("../../types.zig");
const scast = types.scast;
const ops = @import("../../ops.zig");
const constants = @import("../../constants.zig");

const linalg = @import("../../linalg.zig");
const blas = @import("../blas.zig");
const Order = types.Order;
const Uplo = types.Uplo;

/// Performs a rank-1 update of a symmetric packed matrix.
///
/// The `spr` routine performs a matrix-vector operation defined as:
///
/// ```zig
///     A = alpha * x * x^T + A,
/// ```
///
/// where `alpha` is a real scalar, `x` is an `n`-element vector, and `A` is an
/// `n`-by-`n` symmetric matrix, supplied in packed form.
///
/// Signature
/// ---------
/// ```zig
/// fn spr(order: Order, uplo: Uplo, n: i32, alpha: Al, x: [*]const X, incx: i32, ap: [*]A, ctx: anytype) !void
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
/// `alpha` (`bool`, `int`, `float`, `cfloat`, `integer`, `rational`, `real`,
/// `complex` or `expression`): Specifies the scalar `alpha`.
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
pub fn spr(
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
        @compileError("zml.linalg.blas.spr requires alpha to be numeric, got " ++ @typeName(Al));

    comptime if (!types.isManyPointer(X))
        @compileError("zml.linalg.blas.spr requires x to be a many-item pointer, got " ++ @typeName(X));

    X = types.Child(X);

    comptime if (!types.isNumeric(X))
        @compileError("zml.linalg.blas.spr requires x's child type to be numeric, got " ++ @typeName(X));

    comptime if (!types.isManyPointer(A) or types.isConstPointer(A))
        @compileError("zml.linalg.blas.spr requires a to be a mutable many-item pointer, got " ++ @typeName(A));

    A = types.Child(A);

    comptime if (!types.isNumeric(A))
        @compileError("zml.linalg.blas.spr requires a's child type to numeric, got " ++ @typeName(A));

    comptime if (Al == bool and X == bool and A == bool)
        @compileError("zml.linalg.blas.spr does not support alpha, a, x, beta and y all being bool");

    comptime if (types.isArbitraryPrecision(Al) or
        types.isArbitraryPrecision(X) or
        types.isArbitraryPrecision(A))
    {
        // When implemented, expand if
        @compileError("zml.linalg.blas.spr not implemented for arbitrary precision types yet");
    } else {
        types.validateContext(@TypeOf(ctx), .{});
    };

    if (comptime A == X and types.canCoerce(Al, A) and options.link_cblas != null) {
        switch (comptime types.numericType(A)) {
            .float => {
                if (comptime A == f32) {
                    return ci.cblas_sspr(order.toCUInt(), uplo.toCUInt(), scast(c_int, n), scast(A, alpha), x, scast(c_int, incx), ap);
                } else if (comptime A == f64) {
                    return ci.cblas_dspr(order.toCUInt(), uplo.toCUInt(), scast(c_int, n), scast(A, alpha), x, scast(c_int, incx), ap);
                }
            },
            else => {},
        }
    }

    return _spr(order, uplo, n, alpha, x, incx, ap, ctx);
}

fn _spr(
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
        return k_spr(uplo, n, alpha, x, incx, ap, ctx);
    } else {
        return k_spr(uplo.invert(), n, alpha, x, incx, ap, ctx);
    }
}

fn k_spr(
    uplo: Uplo,
    n: i32,
    alpha: anytype,
    x: anytype,
    incx: i32,
    ap: anytype,
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

                        ops.add_( // ap[kk + j] += x[j] * temp
                            &ap[scast(u32, kk + j)],
                            ap[scast(u32, kk + j)],
                            ops.mul(
                                x[scast(u32, j)],
                                temp,
                                ctx,
                            ) catch unreachable,
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

                        ops.add_( // ap[kk + j] += x[jx] * temp
                            &ap[scast(u32, kk + j)],
                            ap[scast(u32, kk + j)],
                            ops.mul(
                                x[scast(u32, jx)],
                                temp,
                                ctx,
                            ) catch unreachable,
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

                        ops.add_( // ap[kk] += x[j] * temp
                            &ap[scast(u32, kk)],
                            ap[scast(u32, kk)],
                            ops.mul(
                                x[scast(u32, j)],
                                temp,
                                ctx,
                            ) catch unreachable,
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

                        ops.add_( // ap[kk] += x[jx] * temp
                            &ap[scast(u32, kk)],
                            ap[scast(u32, kk)],
                            ops.mul(
                                x[scast(u32, jx)],
                                temp,
                                ctx,
                            ) catch unreachable,
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
                    }

                    jx += incx;
                    kk += n - j;
                }
            }
        }
    } else {
        // Arbitrary precision types not supported yet
        @compileError("zml.linalg.blas.spr not implemented for arbitrary precision types yet");
    }

    return;
}
