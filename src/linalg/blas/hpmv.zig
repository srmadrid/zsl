const std = @import("std");

const types = @import("../../types.zig");
const scast = types.scast;
const ops = @import("../../ops.zig");
const constants = @import("../../constants.zig");

const linalg = @import("../../linalg.zig");
const blas = @import("../blas.zig");
const Order = types.Order;
const Uplo = types.Uplo;

/// Computes a matrix-vector product using a Hermitian packed matrix.
///
/// The `hpmv` routine performs a matrix-vector operation defined as:
///
/// ```zig
///     y = alpha * A * x + beta * y,
/// ```
///
/// where `alpha` and `beta` are scalars, `x` and `y` are `n`-element vectors,
/// `A` is an `n`-by-`n` Hermitian matrix, supplied in packed form.
///
/// Signature
/// ---------
/// ```zig
/// fn hpmv(order: Order, uplo: Uplo, n: i32, alpha: Al, ap: [*]const A, x: [*]const X, incx: i32, beta: Be, y: [*]Y, incy: i32, ctx: anytype) !void
/// ```
///
/// Parameters
/// ----------
/// `order` (`Order`): Specifies whether two-dimensional array storage is
/// row-major or column-major.
///
/// `uplo` (`Uplo`): Specifies whether the upper or lower triangular part of the
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
/// `ap` (many-item pointer to `int`, `float`, `cfloat`, `integer`, `rational`,
/// `real`, `complex` or `expression`): Array, size at least
/// `(n * (n + 1)) / 2`.
///
/// `x` (many-item pointer to `int`, `float`, `cfloat`, `integer`, `rational`,
/// `real`, `complex` or `expression`): Array, size at least
/// `1 + (n - 1) * abs(incx)`.
///
/// `incx` (`i32`): Specifies the increment for indexing vector `x`. Must be
/// different from 0.
///
/// `beta` (`bool`, `int`, `float`, `cfloat`, `integer`, `rational`, `real`,
/// `complex` or `expression`): Specifies the scalar `beta`. When `beta` is
/// 0, then `y` need not be set on input.
///
/// `y` (mutable many-item pointer to `int`, `float`, `cfloat`, `integer`,
/// `rational`, `real`, `complex` or `expression`): Array, size at least
/// `1 + (n - 1) * abs(incy)`. On return, contains the result of the
/// operation.
///
/// `incy` (`i32`): Specifies the increment for indexing vector `y`. Must be
/// different from 0.
///
/// Returns
/// -------
/// `void`: The result is stored in `y`.
///
/// Errors
/// ------
/// `linalg.blas.Error.InvalidArgument`: If `n` is less than 0, or if `incx` or
/// `incy` is 0.
///
/// Notes
/// -----
/// If the `link_cblas` option is not `null`, the function will try to call the
/// corresponding CBLAS function, if available. In that case, no errors will be
/// raised even if the arguments are invalid.
pub fn hpmv(
    order: Layout,
    uplo: Uplo,
    n: i32,
    alpha: anytype,
    ap: anytype,
    x: anytype,
    incx: i32,
    beta: anytype,
    y: anytype,
    incy: i32,
    ctx: anytype,
) !void {
    const Al: type = @TypeOf(alpha);
    comptime var A: type = @TypeOf(ap);
    comptime var X: type = @TypeOf(x);
    const Be: type = @TypeOf(beta);
    comptime var Y: type = @TypeOf(y);

    comptime if (!types.isNumeric(Al))
        @compileError("zml.linalg.blas.hpmv requires alpha to be numeric, got " ++ @typeName(Al));

    comptime if (!types.isManyPointer(A))
        @compileError("zml.linalg.blas.hpmv requires ap to be a many-item pointer, got " ++ @typeName(A));

    A = types.Child(A);

    comptime if (!types.isNumeric(A))
        @compileError("zml.linalg.blas.hpmv requires ap's child type to numeric, got " ++ @typeName(A));

    comptime if (!types.isManyPointer(X))
        @compileError("zml.linalg.blas.hpmv requires x to be a many-item pointer, got " ++ @typeName(X));

    X = types.Child(X);

    comptime if (!types.isNumeric(X))
        @compileError("zml.linalg.blas.hpmv requires x's child type to be numeric, got " ++ @typeName(X));

    comptime if (!types.isNumeric(Be))
        @compileError("zml.linalg.blas.hpmv requires beta to be numeric, got " ++ @typeName(Be));

    comptime if (!types.isManyPointer(Y) or types.isConstPointer(Y))
        @compileError("zml.linalg.blas.hpmv requires y to be a mutable many-item pointer, got " ++ @typeName(Y));

    Y = types.Child(Y);

    comptime if (!types.isNumeric(Y))
        @compileError("zml.linalg.blas.hpmv requires y's child type to be numeric, got " ++ @typeName(Y));

    comptime if (Al == bool and A == bool and X == bool and Be == bool and Y == bool)
        @compileError("zml.linalg.blas.hpmv does not support alpha, a, x, beta and y all being bool");

    comptime if (types.isArbitraryPrecision(Al) or
        types.isArbitraryPrecision(A) or
        types.isArbitraryPrecision(X) or
        types.isArbitraryPrecision(Be) or
        types.isArbitraryPrecision(Y))
    {
        // When implemented, expand if
        @compileError("zml.linalg.blas.hpmv not implemented for arbitrary precision types yet");
    } else {
        types.validateContext(@TypeOf(ctx), .{});
    };

    if (comptime A == X and A == Y and types.canCoerce(Al, A) and types.canCoerce(Be, A) and options.link_cblas != null) {
        switch (comptime types.numericType(A)) {
            .cfloat => {
                if (comptime Scalar(A) == f32) {
                    const alpha_casted: A = scast(A, alpha);
                    const beta_casted: A = scast(A, beta);
                    return ci.cblas_chpmv(order.toCUInt(), uplo.toCUInt(), scast(c_int, n), &alpha_casted, ap, x, scast(c_int, incx), &beta_casted, y, scast(c_int, incy));
                } else if (comptime Scalar(A) == f64) {
                    const alpha_casted: A = scast(A, alpha);
                    const beta_casted: A = scast(A, beta);
                    return ci.cblas_zhpmv(order.toCUInt(), uplo.toCUInt(), scast(c_int, n), &alpha_casted, ap, x, scast(c_int, incx), &beta_casted, y, scast(c_int, incy));
                }
            },
            else => {},
        }
    }

    return _hpmv(order, uplo, n, alpha, ap, x, incx, beta, y, incy, ctx);
}

fn _hpmv(
    order: Order,
    uplo: Uplo,
    n: i32,
    alpha: anytype,
    ap: anytype,
    x: anytype,
    incx: i32,
    beta: anytype,
    y: anytype,
    incy: i32,
    ctx: anytype,
) !void {
    if (order == .col_major) {
        return k_hpmv(
            uplo,
            n,
            alpha,
            ap,
            x,
            incx,
            beta,
            y,
            incy,
            true,
            ctx,
        );
    } else {
        return k_hpmv(
            uplo.invert(),
            n,
            ops.conj(alpha, ctx) catch unreachable,
            ap,
            x,
            incx,
            ops.conj(beta, ctx) catch unreachable,
            y,
            incy,
            false,
            ctx,
        );
    }
}

fn k_hpmv(
    uplo: Uplo,
    n: i32,
    alpha: anytype,
    ap: anytype,
    x: anytype,
    incx: i32,
    beta: anytype,
    y: anytype,
    incy: i32,
    noconj: bool,
    ctx: anytype,
) !void {
    const Al: type = @TypeOf(alpha);
    const A: type = types.Child(@TypeOf(ap));
    const X: type = types.Child(@TypeOf(x));
    const C1: type = types.Coerce(Al, X);
    const C2: type = types.Coerce(A, X);
    const Be: type = @TypeOf(beta);
    const Y: type = types.Child(@TypeOf(y));
    const CC: type = types.Coerce(Al, types.Coerce(A, types.Coerce(X, types.Coerce(Be, Y))));

    if (n < 0 or incx == 0 or incy == 0)
        return blas.Error.InvalidArgument;

    // Quick return if possible.
    if (n == 0 or
        (ops.eq(alpha, 0, ctx) catch unreachable and ops.eq(beta, 1, ctx) catch unreachable))
        return;

    const kx: i32 = if (incx < 0) (-n + 1) * incx else 0;
    const ky: i32 = if (incy < 0) (-n + 1) * incy else 0;

    if (comptime !types.isArbitraryPrecision(CC)) {
        // First form  y = beta * y.
        if (ops.ne(beta, 1, ctx) catch unreachable) {
            if (incy == 1) {
                if (ops.eq(beta, 0, ctx) catch unreachable) {
                    for (0..scast(u32, n)) |i| {
                        ops.set( // y[i] = 0
                            &y[i],
                            0,
                            ctx,
                        ) catch unreachable;
                    }
                } else {
                    if (noconj) {
                        for (0..scast(u32, n)) |i| {
                            ops.mul_( // y[i] *= beta
                                &y[i],
                                y[i],
                                beta,
                                ctx,
                            ) catch unreachable;
                        }
                    } else {
                        for (0..scast(u32, n)) |i| {
                            ops.mul_( // y[i] = conj(y[i]) * beta
                                &y[i],
                                ops.conj(y[i], ctx) catch unreachable,
                                beta,
                                ctx,
                            ) catch unreachable;
                        }
                    }
                }
            } else {
                var iy: i32 = ky;
                if (ops.eq(beta, 0, ctx) catch unreachable) {
                    for (0..scast(u32, n)) |_| {
                        ops.set( // y[iy] = 0
                            &y[scast(u32, iy)],
                            0,
                            ctx,
                        ) catch unreachable;

                        iy += incy;
                    }
                } else {
                    if (noconj) {
                        for (0..scast(u32, n)) |_| {
                            ops.mul_( // y[iy] *= beta
                                &y[scast(u32, iy)],
                                y[scast(u32, iy)],
                                beta,
                                ctx,
                            ) catch unreachable;

                            iy += incy;
                        }
                    } else {
                        for (0..scast(u32, n)) |_| {
                            ops.mul_( // y[iy] = conj(y[iy]) * beta
                                &y[scast(u32, iy)],
                                ops.conj(y[scast(u32, iy)], ctx) catch unreachable,
                                beta,
                                ctx,
                            ) catch unreachable;

                            iy += incy;
                        }
                    }
                }
            }
        }

        if (ops.eq(alpha, 0, ctx) catch unreachable) {
            if (!noconj) {
                if (incy == 1) {
                    for (0..scast(u32, n)) |i| {
                        ops.conj_( // y[i] = conj(y[i])
                            &y[i],
                            y[i],
                            ctx,
                        ) catch unreachable;
                    }
                } else {
                    var iy: i32 = if (incy < 0) (-n + 1) * incy else 0;
                    for (0..scast(u32, n)) |_| {
                        ops.conj_( // y[iy] = conj(y[iy])
                            &y[scast(u32, iy)],
                            y[scast(u32, iy)],
                            ctx,
                        ) catch unreachable;

                        iy += incy;
                    }
                }
            }

            return;
        }

        var kk: i32 = 0;
        if (uplo == .upper) {
            if (noconj) {
                if (incx == 1 and incy == 1) {
                    var j: i32 = 0;
                    while (j < n) : (j += 1) {
                        const temp1: C1 = ops.mul( // temp1 = alpha * x[j]
                            x[scast(u32, j)],
                            alpha,
                            ctx,
                        ) catch unreachable;
                        var temp2: C2 = constants.zero(C2, ctx) catch unreachable;

                        var k: i32 = kk;
                        var i: i32 = 0;
                        while (i < j) : (i += 1) {
                            ops.add_( // y[i] += temp1 * ap[k]
                                &y[scast(u32, i)],
                                y[scast(u32, i)],
                                ops.mul(
                                    temp1,
                                    ap[scast(u32, k)],
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            ops.add_( // temp2 += conj(ap[k]) * x[i]
                                &temp2,
                                temp2,
                                ops.mul(
                                    ops.conj(ap[scast(u32, k)], ctx) catch unreachable,
                                    x[scast(u32, i)],
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            k += 1;
                        }

                        ops.add_( // y[j] += temp1 * re(ap[kk + j]) + alpha * temp2
                            &y[scast(u32, j)],
                            y[scast(u32, j)],
                            ops.add(
                                ops.mul(
                                    temp1,
                                    ops.re(ap[scast(u32, kk + j)], ctx) catch unreachable,
                                    ctx,
                                ) catch unreachable,
                                ops.mul(
                                    alpha,
                                    temp2,
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable,
                            ctx,
                        ) catch unreachable;

                        kk += j + 1;
                    }
                } else {
                    var jx: i32 = kx;
                    var jy: i32 = ky;
                    var j: i32 = 0;
                    while (j < n) : (j += 1) {
                        const temp1: C1 = ops.mul( // temp1 = alpha * x[jx]
                            x[scast(u32, jx)],
                            alpha,
                            ctx,
                        ) catch unreachable;
                        var temp2: C2 = constants.zero(C2, ctx) catch unreachable;

                        var ix: i32 = kx;
                        var iy: i32 = ky;
                        var k: i32 = kk;
                        while (k < kk + j) : (k += 1) {
                            ops.add_( // y[iy] += temp1 * ap[k]
                                &y[scast(u32, iy)],
                                y[scast(u32, iy)],
                                ops.mul(
                                    temp1,
                                    ap[scast(u32, k)],
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            ops.add_( // temp2 += conj(ap[k]) * x[ix]
                                &temp2,
                                temp2,
                                ops.mul(
                                    ops.conj(ap[scast(u32, k)], ctx) catch unreachable,
                                    x[scast(u32, ix)],
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            ix += incx;
                            iy += incy;
                        }

                        ops.add_( // y[jy] += temp1 * re(ap[kk + j]) + alpha * temp2
                            &y[scast(u32, jy)],
                            y[scast(u32, jy)],
                            ops.add(
                                ops.mul(
                                    temp1,
                                    ops.re(ap[scast(u32, kk + j)], ctx) catch unreachable,
                                    ctx,
                                ) catch unreachable,
                                ops.mul(
                                    alpha,
                                    temp2,
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable,
                            ctx,
                        ) catch unreachable;

                        jx += incx;
                        jy += incy;
                        kk += j + 1;
                    }
                }
            } else {
                if (incx == 1 and incy == 1) {
                    var j: i32 = 0;
                    while (j < n) : (j += 1) {
                        const temp1: C1 = ops.mul( // temp1 = alpha * conj(x[j])
                            ops.conj(x[scast(u32, j)], ctx) catch unreachable,
                            alpha,
                            ctx,
                        ) catch unreachable;
                        var temp2: C2 = constants.zero(C2, ctx) catch unreachable;

                        var k: i32 = kk;
                        var i: i32 = 0;
                        while (i < j) : (i += 1) {
                            ops.add_( // y[i] += temp1 * ap[k]
                                &y[scast(u32, i)],
                                y[scast(u32, i)],
                                ops.mul(
                                    temp1,
                                    ap[scast(u32, k)],
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            ops.add_( // temp2 += conj(ap[k]) * conj(x[i])
                                &temp2,
                                temp2,
                                ops.mul(
                                    ops.conj(ap[scast(u32, k)], ctx) catch unreachable,
                                    ops.conj(x[scast(u32, i)], ctx) catch unreachable,
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            k += 1;
                        }

                        ops.add_( // y[j] += temp1 * re(ap[kk + j]) + alpha * temp2
                            &y[scast(u32, j)],
                            y[scast(u32, j)],
                            ops.add(
                                ops.mul(
                                    temp1,
                                    ops.re(ap[scast(u32, kk + j)], ctx) catch unreachable,
                                    ctx,
                                ) catch unreachable,
                                ops.mul(
                                    alpha,
                                    temp2,
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable,
                            ctx,
                        ) catch unreachable;

                        kk += j + 1;
                    }
                } else {
                    var jx: i32 = kx;
                    var jy: i32 = ky;
                    var j: i32 = 0;
                    while (j < n) : (j += 1) {
                        const temp1: C1 = ops.mul( // temp1 = alpha * conj(x[jx])
                            ops.conj(x[scast(u32, jx)], ctx) catch unreachable,
                            alpha,
                            ctx,
                        ) catch unreachable;
                        var temp2: C2 = constants.zero(C2, ctx) catch unreachable;

                        var ix: i32 = kx;
                        var iy: i32 = ky;
                        var k: i32 = kk;
                        while (k < kk + j) : (k += 1) {
                            ops.add_( // y[iy] += temp1 * ap[k]
                                &y[scast(u32, iy)],
                                y[scast(u32, iy)],
                                ops.mul(
                                    temp1,
                                    ap[scast(u32, k)],
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            ops.add_( // temp2 += conj(ap[k]) * conj(x[ix])
                                &temp2,
                                temp2,
                                ops.mul(
                                    ops.conj(ap[scast(u32, k)], ctx) catch unreachable,
                                    ops.conj(x[scast(u32, ix)], ctx) catch unreachable,
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            ix += incx;
                            iy += incy;
                        }

                        ops.add_( // y[jy] += temp1 * re(ap[kk + j]) + alpha * temp2
                            &y[scast(u32, jy)],
                            y[scast(u32, jy)],
                            ops.add(
                                ops.mul(
                                    temp1,
                                    ops.re(ap[scast(u32, kk + j)], ctx) catch unreachable,
                                    ctx,
                                ) catch unreachable,
                                ops.mul(
                                    alpha,
                                    temp2,
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable,
                            ctx,
                        ) catch unreachable;

                        jx += incx;
                        jy += incy;
                        kk += j + 1;
                    }
                }
            }
        } else {
            if (noconj) {
                if (incx == 1 and incy == 1) {
                    var j: i32 = 0;
                    while (j < n) : (j += 1) {
                        const temp1: C1 = ops.mul( // temp1 = alpha * x[j]
                            x[scast(u32, j)],
                            alpha,
                            ctx,
                        ) catch unreachable;
                        var temp2: C2 = constants.zero(C2, ctx) catch unreachable;

                        ops.add_( // y[j] += temp1 * re(ap[kk])
                            &y[scast(u32, j)],
                            y[scast(u32, j)],
                            ops.mul(
                                temp1,
                                ops.re(ap[scast(u32, kk)], ctx) catch unreachable,
                                ctx,
                            ) catch unreachable,
                            ctx,
                        ) catch unreachable;

                        var k: i32 = kk + 1;
                        var i: i32 = j + 1;
                        while (i < n) : (i += 1) {
                            ops.add_( // y[i] += temp1 * ap[k]
                                &y[scast(u32, i)],
                                y[scast(u32, i)],
                                ops.mul(
                                    temp1,
                                    ap[scast(u32, k)],
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            ops.add_( // temp2 += conj(ap[k]) * x[i]
                                &temp2,
                                temp2,
                                ops.mul(
                                    ops.conj(ap[scast(u32, k)], ctx) catch unreachable,
                                    x[scast(u32, i)],
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            k += 1;
                        }

                        ops.add_( // y[j] += alpha * temp2
                            &y[scast(u32, j)],
                            y[scast(u32, j)],
                            ops.mul(
                                alpha,
                                temp2,
                                ctx,
                            ) catch unreachable,
                            ctx,
                        ) catch unreachable;

                        kk += n - j;
                    }
                } else {
                    var jx: i32 = kx;
                    var jy: i32 = ky;
                    var j: i32 = 0;
                    while (j < n) : (j += 1) {
                        const temp1: C1 = ops.mul( // temp1 = alpha * x[jx]
                            x[scast(u32, jx)],
                            alpha,
                            ctx,
                        ) catch unreachable;
                        var temp2: C2 = constants.zero(C2, ctx) catch unreachable;

                        ops.add_( // y[jy] += temp1 * re(ap[kk])
                            &y[scast(u32, jy)],
                            y[scast(u32, jy)],
                            ops.mul(
                                temp1,
                                ops.re(ap[scast(u32, kk)], ctx) catch unreachable,
                                ctx,
                            ) catch unreachable,
                            ctx,
                        ) catch unreachable;

                        var ix: i32 = jx;
                        var iy: i32 = jy;
                        var k: i32 = kk + 1;
                        while (k < kk + n - j) : (k += 1) {
                            ix += incx;
                            iy += incy;

                            ops.add_( // y[iy] += temp1 * ap[k]
                                &y[scast(u32, iy)],
                                y[scast(u32, iy)],
                                ops.mul(
                                    temp1,
                                    ap[scast(u32, k)],
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            ops.add_( // temp2 += conj(ap[k]) * x[ix]
                                &temp2,
                                temp2,
                                ops.mul(
                                    ops.conj(ap[scast(u32, k)], ctx) catch unreachable,
                                    x[scast(u32, ix)],
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;
                        }

                        ops.add_( // y[jy] += alpha * temp2
                            &y[scast(u32, jy)],
                            y[scast(u32, jy)],
                            ops.mul(
                                alpha,
                                temp2,
                                ctx,
                            ) catch unreachable,
                            ctx,
                        ) catch unreachable;

                        jx += incx;
                        jy += incy;
                        kk += n - j;
                    }
                }
            } else {
                if (incx == 1 and incy == 1) {
                    var j: i32 = 0;
                    while (j < n) : (j += 1) {
                        const temp1: C1 = ops.mul( // temp1 = alpha * conj(x[j])
                            ops.conj(x[scast(u32, j)], ctx) catch unreachable,
                            alpha,
                            ctx,
                        ) catch unreachable;
                        var temp2: C2 = constants.zero(C2, ctx) catch unreachable;

                        ops.add_( // y[j] += temp1 * re(ap[kk])
                            &y[scast(u32, j)],
                            y[scast(u32, j)],
                            ops.mul(
                                temp1,
                                ops.re(ap[scast(u32, kk)], ctx) catch unreachable,
                                ctx,
                            ) catch unreachable,
                            ctx,
                        ) catch unreachable;

                        var k: i32 = kk + 1;
                        var i: i32 = j + 1;
                        while (i < n) : (i += 1) {
                            ops.add_( // y[i] += temp1 * ap[k]
                                &y[scast(u32, i)],
                                y[scast(u32, i)],
                                ops.mul(
                                    temp1,
                                    ap[scast(u32, k)],
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            ops.add_( // temp2 += conj(ap[k]) * conj(x[i])
                                &temp2,
                                temp2,
                                ops.mul(
                                    ops.conj(ap[scast(u32, k)], ctx) catch unreachable,
                                    ops.conj(x[scast(u32, i)], ctx) catch unreachable,
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            k += 1;
                        }

                        ops.add_( // y[j] += alpha * temp2
                            &y[scast(u32, j)],
                            y[scast(u32, j)],
                            ops.mul(
                                alpha,
                                temp2,
                                ctx,
                            ) catch unreachable,
                            ctx,
                        ) catch unreachable;

                        kk += n - j;
                    }
                } else {
                    var jx: i32 = kx;
                    var jy: i32 = ky;
                    var j: i32 = 0;
                    while (j < n) : (j += 1) {
                        const temp1: C1 = ops.mul( // temp1 = alpha * conj(x[jx])
                            ops.conj(x[scast(u32, jx)], ctx) catch unreachable,
                            alpha,
                            ctx,
                        ) catch unreachable;
                        var temp2: C2 = constants.zero(C2, ctx) catch unreachable;

                        ops.add_( // y[jy] += temp1 * re(ap[kk])
                            &y[scast(u32, jy)],
                            y[scast(u32, jy)],
                            ops.mul(
                                temp1,
                                ops.re(ap[scast(u32, kk)], ctx) catch unreachable,
                                ctx,
                            ) catch unreachable,
                            ctx,
                        ) catch unreachable;

                        var ix: i32 = jx;
                        var iy: i32 = jy;
                        var k: i32 = kk + 1;
                        while (k < kk + n - j) : (k += 1) {
                            ix += incx;
                            iy += incy;

                            ops.add_( // y[iy] += temp1 * ap[k]
                                &y[scast(u32, iy)],
                                y[scast(u32, iy)],
                                ops.mul(
                                    temp1,
                                    ap[scast(u32, k)],
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            ops.add_( // temp2 += conj(ap[k]) * conj(x[ix])
                                &temp2,
                                temp2,
                                ops.mul(
                                    ops.conj(ap[scast(u32, k)], ctx) catch unreachable,
                                    ops.conj(x[scast(u32, ix)], ctx) catch unreachable,
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;
                        }

                        ops.add_( // y[jy] += alpha * temp2
                            &y[scast(u32, jy)],
                            y[scast(u32, jy)],
                            ops.mul(
                                alpha,
                                temp2,
                                ctx,
                            ) catch unreachable,
                            ctx,
                        ) catch unreachable;

                        jx += incx;
                        jy += incy;
                        kk += n - j;
                    }
                }
            }
        }

        if (!noconj) {
            if (incy == 1) {
                for (0..scast(u32, n)) |i| {
                    ops.conj_( // y[i] = conj(y[i])
                        &y[i],
                        y[i],
                        ctx,
                    ) catch unreachable;
                }
            } else {
                var iy: i32 = if (incy < 0) (-n + 1) * incy else 0;
                for (0..scast(u32, n)) |_| {
                    ops.conj_( // y[iy] = conj(y[iy])
                        &y[scast(u32, iy)],
                        y[scast(u32, iy)],
                        ctx,
                    ) catch unreachable;

                    iy += incy;
                }
            }
        }
    } else {
        // Arbitrary precision types not supported yet
        @compileError("zml.linalg.blas.hpmv not implemented for arbitrary precision types yet");
    }

    return;
}
