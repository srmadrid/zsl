const std = @import("std");

const types = @import("../../types.zig");
const scast = types.scast;
const ops = @import("../../ops.zig");
const constants = @import("../../constants.zig");
const int = @import("../../int.zig");

const linalg = @import("../../linalg.zig");
const blas = @import("../blas.zig");
const Order = types.Order;
const Uplo = types.Uplo;

/// Computes a matrix-vector product using a Hermitian matrix.
///
/// The `hemv` routine performs a matrix-vector operation defined as:
///
/// ```zig
///     y = alpha * A * x + beta * y,
/// ```
///
/// where `alpha` and `beta` are scalars, `x` and `y` are `n`-element vectors,
/// `A` is an `n`-by-`n` Hermitian matrix.
///
/// Signature
/// ---------
/// ```zig
/// fn hemv(order: Order, uplo: Uplo, n: i32, alpha: Al, a: [*]const A, lda: i32, x: [*]const X, incx: i32, beta: Be, y: [*]Y, incy: i32, ctx: anytype) !void
/// ```
///
/// Parameters
/// ----------
/// `order` (`Order`): Specifies whether two-dimensional array storage is
/// row-major or column-major.
///
/// `uplo` (`Uplo`): Specifies whether the upper or lower triangular part of the
/// Hermitian matrix `A` is used:
/// - If `uplo = upper`, then the upper triangular part of the matrix `A` is
/// used.
/// - If `uplo = lower`, then the lower triangular part of the matrix `A` is
/// used.
///
/// `n` (`i32`): Specifies the order of the matrix `A`. Must be greater than
/// or equal to 0.
///
/// `alpha` (`bool`, `int`, `float`, `cfloat`, `integer`, `rational`, `real`,
/// `complex` or `expression`): Specifies the scalar `alpha`.
///
/// `a` (many-item pointer to `int`, `float`, `cfloat`, `integer`, `rational`,
/// `real`, `complex` or `expression`): Array, size at least `lda * n`.
///
/// `lda` (`i32`): Specifies the leading dimension of `a` as declared in the
/// calling (sub)program. Must be greater than or equal to `max(1, n)`.
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
/// `linalg.blas.Error.InvalidArgument`: If `n` is less than 0, if `lda` is less
/// than `max(1, n)`, or if `incx` or `incy` is 0.
///
/// Notes
/// -----
/// If the `link_cblas` option is not `null`, the function will try to call the
/// corresponding CBLAS function, if available. In that case, no errors will be
/// raised even if the arguments are invalid.
pub fn hemv(
    order: Layout,
    uplo: Uplo,
    n: i32,
    alpha: anytype,
    a: anytype,
    lda: i32,
    x: anytype,
    incx: i32,
    beta: anytype,
    y: anytype,
    incy: i32,
    ctx: anytype,
) !void {
    const Al: type = @TypeOf(alpha);
    comptime var A: type = @TypeOf(a);
    comptime var X: type = @TypeOf(x);
    const Be: type = @TypeOf(beta);
    comptime var Y: type = @TypeOf(y);

    comptime if (!types.isNumeric(Al))
        @compileError("zml.linalg.blas.hemv requires alpha to be numeric, got " ++ @typeName(Al));

    comptime if (!types.isManyPointer(A))
        @compileError("zml.linalg.blas.hemv requires a to be a many-item pointer, got " ++ @typeName(A));

    A = types.Child(A);

    comptime if (!types.isNumeric(A))
        @compileError("zml.linalg.blas.hemv requires a's child type to numeric, got " ++ @typeName(A));

    comptime if (!types.isManyPointer(X))
        @compileError("zml.linalg.blas.hemv requires x to be a many-item pointer, got " ++ @typeName(X));

    X = types.Child(X);

    comptime if (!types.isNumeric(X))
        @compileError("zml.linalg.blas.hemv requires x's child type to be numeric, got " ++ @typeName(X));

    comptime if (!types.isNumeric(Be))
        @compileError("zml.linalg.blas.hemv requires beta to be numeric, got " ++ @typeName(Be));

    comptime if (!types.isManyPointer(Y) or types.isConstPointer(Y))
        @compileError("zml.linalg.blas.hemv requires y to be a mutable many-item pointer, got " ++ @typeName(Y));

    Y = types.Child(Y);

    comptime if (!types.isNumeric(Y))
        @compileError("zml.linalg.blas.hemv requires y's child type to be numeric, got " ++ @typeName(Y));

    comptime if (Al == bool and A == bool and X == bool and Be == bool and Y == bool)
        @compileError("zml.linalg.blas.hemv does not support alpha, a, x, beta and y all being bool");

    comptime if (types.isArbitraryPrecision(Al) or
        types.isArbitraryPrecision(A) or
        types.isArbitraryPrecision(X) or
        types.isArbitraryPrecision(Be) or
        types.isArbitraryPrecision(Y))
    {
        // When implemented, expand if
        @compileError("zml.linalg.blas.hemv not implemented for arbitrary precision types yet");
    } else {
        types.validateContext(@TypeOf(ctx), .{});
    };

    if (comptime A == X and A == Y and types.canCoerce(Al, A) and types.canCoerce(Be, A) and options.link_cblas != null) {
        switch (comptime types.numericType(A)) {
            .cfloat => {
                if (comptime Scalar(A) == f32) {
                    const alpha_casted: A = scast(A, alpha);
                    const beta_casted: A = scast(A, beta);
                    return ci.cblas_chemv(order.toCUInt(), uplo.toCUInt(), scast(c_int, n), &alpha_casted, a, scast(c_int, lda), x, scast(c_int, incx), &beta_casted, y, scast(c_int, incy));
                } else if (comptime Scalar(A) == f64) {
                    const alpha_casted: A = scast(A, alpha);
                    const beta_casted: A = scast(A, beta);
                    return ci.cblas_zhemv(order.toCUInt(), uplo.toCUInt(), scast(c_int, n), &alpha_casted, a, scast(c_int, lda), x, scast(c_int, incx), &beta_casted, y, scast(c_int, incy));
                }
            },
            else => {},
        }
    }

    return _hemv(order, uplo, n, alpha, a, lda, x, incx, beta, y, incy, ctx);
}

fn _hemv(
    order: Order,
    uplo: Uplo,
    n: i32,
    alpha: anytype,
    a: anytype,
    lda: i32,
    x: anytype,
    incx: i32,
    beta: anytype,
    y: anytype,
    incy: i32,
    ctx: anytype,
) !void {
    if (order == .col_major) {
        return k_hemv(
            uplo,
            n,
            alpha,
            a,
            lda,
            x,
            incx,
            beta,
            y,
            incy,
            true,
            ctx,
        );
    } else {
        return k_hemv(
            uplo.invert(),
            n,
            ops.conj(alpha, ctx) catch unreachable,
            a,
            lda,
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

fn k_hemv(
    uplo: Uplo,
    n: i32,
    alpha: anytype,
    a: anytype,
    lda: i32,
    x: anytype,
    incx: i32,
    beta: anytype,
    y: anytype,
    incy: i32,
    noconj: bool,
    ctx: anytype,
) !void {
    const Al: type = @TypeOf(alpha);
    const A: type = types.Child(@TypeOf(a));
    const X: type = types.Child(@TypeOf(x));
    const C1: type = types.Coerce(Al, X);
    const C2: type = types.Coerce(A, X);
    const Be: type = @TypeOf(beta);
    const Y: type = types.Child(@TypeOf(y));
    const CC: type = types.Coerce(Al, types.Coerce(A, types.Coerce(X, types.Coerce(Be, Y))));

    if (n < 0 or lda < int.max(1, n) or incx == 0 or incy == 0)
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

                        var i: i32 = 0;
                        while (i < j) : (i += 1) {
                            ops.add_( // y[i] += temp1 * a[i + j * lda]
                                &y[scast(u32, i)],
                                y[scast(u32, i)],
                                ops.mul(
                                    a[scast(u32, i + j * lda)],
                                    temp1,
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            ops.add_( // temp2 += conj(a[i + j * lda]) * x[i]
                                &temp2,
                                temp2,
                                ops.mul(
                                    ops.conj(a[scast(u32, i + j * lda)], ctx) catch unreachable,
                                    x[scast(u32, i)],
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;
                        }

                        ops.add_( // y[j] += temp1 * re(a[j + j * lda]) + alpha * temp2
                            &y[scast(u32, j)],
                            y[scast(u32, j)],
                            ops.add(
                                ops.mul(
                                    temp1,
                                    ops.re(a[scast(u32, j + j * lda)], ctx) catch unreachable,
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
                        var i: i32 = 0;
                        while (i < j) : (i += 1) {
                            ops.add_( // y[iy] += temp1 * a[i + j * lda]
                                &y[scast(u32, iy)],
                                y[scast(u32, iy)],
                                ops.mul(
                                    a[scast(u32, i + j * lda)],
                                    temp1,
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            ops.add_( // temp2 += conj(a[i + j * lda]) * x[ix]
                                &temp2,
                                temp2,
                                ops.mul(
                                    ops.conj(a[scast(u32, i + j * lda)], ctx) catch unreachable,
                                    x[scast(u32, ix)],
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            ix += incx;
                            iy += incy;
                        }

                        ops.add_( // y[jy] += temp1 * re(a[j + j * lda]) + alpha * temp2
                            &y[scast(u32, jy)],
                            y[scast(u32, jy)],
                            ops.add(
                                ops.mul(
                                    temp1,
                                    ops.re(a[scast(u32, j + j * lda)], ctx) catch unreachable,
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

                        var i: i32 = 0;
                        while (i < j) : (i += 1) {
                            ops.add_( // y[i] += temp1 * a[i + j * lda]
                                &y[scast(u32, i)],
                                y[scast(u32, i)],
                                ops.mul(
                                    a[scast(u32, i + j * lda)],
                                    temp1,
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            ops.add_( // temp2 += conj(a[i + j * lda]) * conj(x[i])
                                &temp2,
                                temp2,
                                ops.mul(
                                    ops.conj(a[scast(u32, i + j * lda)], ctx) catch unreachable,
                                    ops.conj(x[scast(u32, i)], ctx) catch unreachable,
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;
                        }

                        ops.add_( // y[j] += temp1 * re(a[j + j * lda]) + alpha * temp2
                            &y[scast(u32, j)],
                            y[scast(u32, j)],
                            ops.add(
                                ops.mul(
                                    temp1,
                                    ops.re(a[scast(u32, j + j * lda)], ctx) catch unreachable,
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
                        var i: i32 = 0;
                        while (i < j) : (i += 1) {
                            ops.add_( // y[iy] += temp1 * a[i + j * lda]
                                &y[scast(u32, iy)],
                                y[scast(u32, iy)],
                                ops.mul(
                                    a[scast(u32, i + j * lda)],
                                    temp1,
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            ops.add_( // temp2 += conj(a[i + j * lda]) * conj(x[ix])
                                &temp2,
                                temp2,
                                ops.mul(
                                    ops.conj(a[scast(u32, i + j * lda)], ctx) catch unreachable,
                                    ops.conj(x[scast(u32, ix)], ctx) catch unreachable,
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            ix += incx;
                            iy += incy;
                        }

                        ops.add_( // y[jy] += temp1 * re(a[j + j * lda]) + alpha * temp2
                            &y[scast(u32, jy)],
                            y[scast(u32, jy)],
                            ops.add(
                                ops.mul(
                                    temp1,
                                    ops.re(a[scast(u32, j + j * lda)], ctx) catch unreachable,
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

                        ops.add_( // y[j] += temp1 * re(a[j + j * lda])
                            &y[scast(u32, j)],
                            y[scast(u32, j)],
                            ops.mul(
                                temp1,
                                ops.re(a[scast(u32, j + j * lda)], ctx) catch unreachable,
                                ctx,
                            ) catch unreachable,
                            ctx,
                        ) catch unreachable;

                        var i: i32 = j + 1;
                        while (i < n) : (i += 1) {
                            ops.add_( // y[i] += temp1 * a[i + j * lda]
                                &y[scast(u32, i)],
                                y[scast(u32, i)],
                                ops.mul(
                                    a[scast(u32, i + j * lda)],
                                    temp1,
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            ops.add_( // temp2 += conj(a[i + j * lda]) * x[i]
                                &temp2,
                                temp2,
                                ops.mul(
                                    ops.conj(a[scast(u32, i + j * lda)], ctx) catch unreachable,
                                    x[scast(u32, i)],
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;
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

                        ops.add_( // y[jy] += temp1 * re(a[j + j * lda])
                            &y[scast(u32, jy)],
                            y[scast(u32, jy)],
                            ops.mul(
                                temp1,
                                ops.re(a[scast(u32, j + j * lda)], ctx) catch unreachable,
                                ctx,
                            ) catch unreachable,
                            ctx,
                        ) catch unreachable;

                        var ix: i32 = jx;
                        var iy: i32 = jy;
                        var i: i32 = j + 1;
                        while (i < n) : (i += 1) {
                            ix += incx;
                            iy += incy;

                            ops.add_( // y[iy] += temp1 * a[i + j * lda]
                                &y[scast(u32, iy)],
                                y[scast(u32, iy)],
                                ops.mul(
                                    a[scast(u32, i + j * lda)],
                                    temp1,
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            ops.add_( // temp2 += conj(a[i + j * lda]) * x[ix]
                                &temp2,
                                temp2,
                                ops.mul(
                                    ops.conj(a[scast(u32, i + j * lda)], ctx) catch unreachable,
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

                        ops.add_( // y[j] += temp1 * re(a[j + j * lda])
                            &y[scast(u32, j)],
                            y[scast(u32, j)],
                            ops.mul(
                                temp1,
                                ops.re(a[scast(u32, j + j * lda)], ctx) catch unreachable,
                                ctx,
                            ) catch unreachable,
                            ctx,
                        ) catch unreachable;

                        var i: i32 = j + 1;
                        while (i < n) : (i += 1) {
                            ops.add_( // y[i] += temp1 * a[i + j * lda]
                                &y[scast(u32, i)],
                                y[scast(u32, i)],
                                ops.mul(
                                    a[scast(u32, i + j * lda)],
                                    temp1,
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            ops.add_( // temp2 += conj(a[i + j * lda]) * conj(x[i])
                                &temp2,
                                temp2,
                                ops.mul(
                                    ops.conj(a[scast(u32, i + j * lda)], ctx) catch unreachable,
                                    ops.conj(x[scast(u32, i)], ctx) catch unreachable,
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;
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

                        ops.add_( // y[jy] += temp1 * re(a[j + j * lda])
                            &y[scast(u32, jy)],
                            y[scast(u32, jy)],
                            ops.mul(
                                temp1,
                                ops.re(a[scast(u32, j + j * lda)], ctx) catch unreachable,
                                ctx,
                            ) catch unreachable,
                            ctx,
                        ) catch unreachable;

                        var ix: i32 = jx;
                        var iy: i32 = jy;
                        var i: i32 = j + 1;
                        while (i < n) : (i += 1) {
                            ix += incx;
                            iy += incy;

                            ops.add_( // y[iy] += temp1 * a[i + j * lda]
                                &y[scast(u32, iy)],
                                y[scast(u32, iy)],
                                ops.mul(
                                    a[scast(u32, i + j * lda)],
                                    temp1,
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            ops.add_( // temp2 += conj(a[i + j * lda]) * conj(x[ix])
                                &temp2,
                                temp2,
                                ops.mul(
                                    ops.conj(a[scast(u32, i + j * lda)], ctx) catch unreachable,
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
        @compileError("zml.linalg.blas.hemv not implemented for arbitrary precision types yet");
    }

    return;
}
