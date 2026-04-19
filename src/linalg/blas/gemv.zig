const std = @import("std");

const types = @import("../../types.zig");
const scast = types.scast;
const ops = @import("../../ops.zig");
const constants = @import("../../constants.zig");
const int = @import("../../int.zig");

const linalg = @import("../../linalg.zig");
const blas = @import("../blas.zig");
const Order = types.Order;
const Transpose = linalg.Transpose;

/// Computes a matrix-vector product using a general matrix.
///
/// The `gemv` routine performs a matrix-vector operation defined as:
///
/// ```zig
///     y = alpha * A * x + beta * y,
/// ```
///
/// or
///
/// ```zig
///     y = alpha * A^T * x + beta * y,
/// ```
///
/// or
///
/// ```zig
///     y = alpha * conj(A) * x + beta * y,
/// ```
///
/// or
///
/// ```zig
///     y = alpha * A^H * x + beta * y,
/// ```
///
/// where `alpha` and `beta` are scalars, `x` and `y` are vectors, `A` is an
/// `m`-by-`n` matrix.
///
/// Signature
/// ---------
/// ```zig
/// fn gemv(order: Order, transa: Transpose, m: i32, n: i32, alpha: Al, a: [*]const A, lda: i32, x: [*]const X, incx: i32, beta: Be, y: [*]Y, incy: i32, ctx: anytype) !void
/// ```
///
/// Parameters
/// ----------
/// `order` (`Order`): Specifies whether two-dimensional array storage is
/// row-major or column-major.
///
/// `transa` (`Transpose`): Specifies the operation to be performed on `A`:
/// - `no_transpose`: `y = alpha * A * x + beta * y`
/// - `transpose`: `y = alpha * A^T * x + beta * y`
/// - `conj_no_transpose`: `y = alpha * conj(A) * x + beta * y`
/// - `conj_transpose`: `y = alpha * A^H * x + beta * y`
///
/// `m` (`i32`): Specifies the number of rows of the matrix `A`. Must be
/// greater than or equal to 0.
///
/// `n` (`i32`): Specifies the number of columns of the matrix `A`. Must be
/// greater than or equal to 0.
///
/// `alpha` (`bool`, `int`, `float`, `cfloat`, `integer`, `rational`, `real`,
/// `complex` or `expression`): Specifies the scalar `alpha`.
///
/// `a` (many-item pointer to `int`, `float`, `cfloat`, `integer`, `rational`,
/// `real`, `complex` or `expression`): Array, size at least `lda * k`, where
/// `k` is `n` when `order` is `col_major`, or `m` when `order` is `row_major`.
///
/// `lda` (`i32`): Specifies the leading dimension of `a` as declared in the
/// calling (sub)program. Must be greater than or equal to `max(1, m)` when
/// `order` is `col_major`, or `max(1, n)` when `order` is `row_major`.
///
/// `x` (many-item pointer to `int`, `float`, `cfloat`, `integer`, `rational`,
/// `real`, `complex` or `expression`): Array, size at least
/// `1 + (n - 1) * abs(incx)` when `transa` is `no_transpose` or
/// `conj_no_transpose`, or `1 + (m - 1) * abs(incx)` otherwise.
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
/// `1 + (m - 1) * abs(incy)` when `transa` is `no_transpose` or
/// `conj_no_transpose`, or `1 + (n - 1) * abs(incy)` otherwise. On return,
/// contains the result of the operation.
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
/// `linalg.blas.Error.InvalidArgument`: If `m` or `n` are less than 0, if `lda`
/// is less than `max(1, m)` or `max(1, n)`, or if `incx` or `incy` are 0.
///
/// Notes
/// -----
/// If the `link_cblas` option is not `null`, the function will try to call the
/// corresponding CBLAS function, if available. In that case, no errors will be
/// raised even if the arguments are invalid.
pub fn gemv(
    order: Layout,
    transa: Transpose,
    m: i32,
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
        @compileError("zml.linalg.blas.gemv requires alpha to be numeric, got " ++ @typeName(Al));

    comptime if (!types.isManyPointer(A))
        @compileError("zml.linalg.blas.gemv requires a to be a many-item pointer, got " ++ @typeName(A));

    A = types.Child(A);

    comptime if (!types.isNumeric(A))
        @compileError("zml.linalg.blas.gemv requires a's child type to numeric, got " ++ @typeName(A));

    comptime if (!types.isManyPointer(X))
        @compileError("zml.linalg.blas.gemv requires x to be a many-item pointer, got " ++ @typeName(X));

    X = types.Child(X);

    comptime if (!types.isNumeric(X))
        @compileError("zml.linalg.blas.gemv requires x's child type to be numeric, got " ++ @typeName(X));

    comptime if (!types.isNumeric(Be))
        @compileError("zml.linalg.blas.gemv requires beta to be numeric, got " ++ @typeName(Be));

    comptime if (!types.isManyPointer(Y) or types.isConstPointer(Y))
        @compileError("zml.linalg.blas.gemv requires y to be a mutable many-item pointer, got " ++ @typeName(Y));

    Y = types.Child(Y);

    comptime if (!types.isNumeric(Y))
        @compileError("zml.linalg.blas.gemv requires y's child type to be numeric, got " ++ @typeName(Y));

    comptime if (Al == bool and A == bool and X == bool and Be == bool and Y == bool)
        @compileError("zml.linalg.blas.gemv does not support alpha, a, x, beta and y all being bool");

    comptime if (types.isArbitraryPrecision(Al) or
        types.isArbitraryPrecision(A) or
        types.isArbitraryPrecision(X) or
        types.isArbitraryPrecision(Be) or
        types.isArbitraryPrecision(Y))
    {
        // When implemented, expand if
        @compileError("zml.linalg.blas.gemv not implemented for arbitrary precision types yet");
    } else {
        types.validateContext(@TypeOf(ctx), .{});
    };

    if (comptime A == X and A == Y and types.canCoerce(Al, A) and types.canCoerce(Be, A) and options.link_cblas != null) {
        switch (comptime types.numericType(A)) {
            .float => {
                if (comptime A == f32) {
                    return ci.cblas_sgemv(order.toCUInt(), transa.toCUInt(), scast(c_int, m), scast(c_int, n), scast(A, alpha), a, scast(c_int, lda), x, scast(c_int, incx), scast(A, beta), y, scast(c_int, incy));
                } else if (comptime A == f64) {
                    return ci.cblas_dgemv(order.toCUInt(), transa.toCUInt(), scast(c_int, m), scast(c_int, n), scast(A, alpha), a, scast(c_int, lda), x, scast(c_int, incx), scast(A, beta), y, scast(c_int, incy));
                }
            },
            .cfloat => {
                if (comptime Scalar(A) == f32) {
                    const alpha_casted: A = scast(A, alpha);
                    const beta_casted: A = scast(A, beta);
                    return ci.cblas_cgemv(order.toCUInt(), transa.toCUInt(), scast(c_int, m), scast(c_int, n), &alpha_casted, a, scast(c_int, lda), x, scast(c_int, incx), &beta_casted, y, scast(c_int, incy));
                } else if (comptime Scalar(A) == f64) {
                    const alpha_casted: A = scast(A, alpha);
                    const beta_casted: A = scast(A, beta);
                    return ci.cblas_zgemv(order.toCUInt(), transa.toCUInt(), scast(c_int, m), scast(c_int, n), &alpha_casted, a, scast(c_int, lda), x, scast(c_int, incx), &beta_casted, y, scast(c_int, incy));
                }
            },
            else => {},
        }
    }

    return _gemv(order, transa, m, n, alpha, a, lda, x, incx, beta, y, incy, ctx);
}

fn _gemv(
    order: Order,
    transa: Transpose,
    m: i32,
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
        return k_gemv(
            transa,
            m,
            n,
            alpha,
            a,
            lda,
            x,
            incx,
            beta,
            y,
            incy,
            ctx,
        );
    } else {
        return k_gemv(
            transa.invert(),
            n,
            m,
            alpha,
            a,
            lda,
            x,
            incx,
            beta,
            y,
            incy,
            ctx,
        );
    }
}

fn k_gemv(
    transa: Transpose,
    m: i32,
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
    const A: type = types.Child(@TypeOf(a));
    const X: type = types.Child(@TypeOf(x));
    const C1: type = types.Coerce(Al, X);
    const C2: type = types.Coerce(A, X);
    const Be: type = @TypeOf(beta);
    const Y: type = types.Child(@TypeOf(y));
    const CC: type = types.Coerce(Al, types.Coerce(A, types.Coerce(X, types.Coerce(Be, Y))));

    if (m < 0 or n < 0 or lda < int.max(1, m) or incx == 0 or incy == 0)
        return blas.Error.InvalidArgument;

    // Quick return if possible.
    if (m == 0 or n == 0 or
        (ops.eq(alpha, 0, ctx) catch unreachable and ops.eq(beta, 1, ctx) catch unreachable))
        return;

    const noconj: bool = transa == .no_trans or transa == .trans;

    // Set lenx and leny, the lengths of the vectors x and y, and set up the
    // start points in x and y.
    var lenx: i32 = 0;
    var leny: i32 = 0;
    if (transa == .no_trans or transa == .conj_no_trans) {
        lenx = n;
        leny = m;
    } else {
        lenx = m;
        leny = n;
    }

    const kx: i32 = if (incx < 0) (-lenx + 1) * incx else 0;
    const ky: i32 = if (incy < 0) (-leny + 1) * incy else 0;

    if (comptime !types.isArbitraryPrecision(CC)) {
        // First form  y = beta * y.
        if (ops.ne(beta, 1, ctx) catch unreachable) {
            if (incy == 1) {
                if (ops.eq(beta, 0, ctx) catch unreachable) {
                    for (0..scast(u32, leny)) |i| {
                        ops.set( // y[i] = 0
                            &y[i],
                            0,
                            ctx,
                        ) catch unreachable;
                    }
                } else {
                    for (0..scast(u32, leny)) |i| {
                        ops.mul_( // y[i] *= beta
                            &y[i],
                            y[i],
                            beta,
                            ctx,
                        ) catch unreachable;
                    }
                }
            } else {
                var iy: i32 = ky;
                if (ops.eq(beta, 0, ctx) catch unreachable) {
                    for (0..scast(u32, leny)) |_| {
                        ops.set( // y[iy] = 0
                            &y[scast(u32, iy)],
                            0,
                            ctx,
                        ) catch unreachable;

                        iy += incy;
                    }
                } else {
                    for (0..scast(u32, leny)) |_| {
                        ops.mul_( // y[iy] *= beta
                            &y[scast(u32, iy)],
                            y[scast(u32, iy)],
                            beta,
                            ctx,
                        ) catch unreachable;

                        iy += incy;
                    }
                }
            }
        }

        if (ops.eq(alpha, 0, ctx) catch unreachable) return;

        if (transa == .no_trans or transa == .conj_no_trans) {
            // Form  y = alpha * A * x + y  or  y = alpha * conj(A) * x + y.
            var jx: i32 = kx;
            if (incy == 1) {
                var j: i32 = 0;
                while (j < n) : (j += 1) {
                    const temp: C1 = ops.mul( // temp = alpha * x[jx]
                        alpha,
                        x[scast(u32, jx)],
                        ctx,
                    ) catch unreachable;

                    if (noconj) {
                        var i: i32 = 0;
                        while (i < m) : (i += 1) {
                            ops.add_( // y[i] += temp * a[i + j * lda]
                                &y[scast(u32, i)],
                                y[scast(u32, i)],
                                ops.mul(
                                    temp,
                                    a[scast(u32, i + j * lda)],
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;
                        }
                    } else {
                        var i: i32 = 0;
                        while (i < m) : (i += 1) {
                            ops.add_( // y[i] += temp * conj(a[i + j * lda])
                                &y[scast(u32, i)],
                                y[scast(u32, i)],
                                ops.mul(
                                    temp,
                                    ops.conj(a[scast(u32, i + j * lda)], ctx) catch unreachable,
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;
                        }
                    }

                    jx += incx;
                }
            } else {
                var j: i32 = 0;
                while (j < n) : (j += 1) {
                    const temp: C1 = ops.mul( // temp = alpha * x[jx]
                        alpha,
                        x[scast(u32, jx)],
                        ctx,
                    ) catch unreachable;

                    if (noconj) {
                        var iy: i32 = ky;
                        var i: i32 = 0;
                        while (i < m) : (i += 1) {
                            ops.add_( // y[iy] += temp * a[i + j * lda]
                                &y[scast(u32, iy)],
                                y[scast(u32, iy)],
                                ops.mul(
                                    temp,
                                    a[scast(u32, i + j * lda)],
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            iy += incy;
                        }
                    } else {
                        var iy: i32 = ky;
                        var i: i32 = 0;
                        while (i < m) : (i += 1) {
                            ops.add_( // y[iy] += temp * conj(a[i + j * lda])
                                &y[scast(u32, iy)],
                                y[scast(u32, iy)],
                                ops.mul(
                                    temp,
                                    ops.conj(a[scast(u32, i + j * lda)], ctx) catch unreachable,
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            iy += incy;
                        }
                    }

                    jx += incx;
                }
            }
        } else {
            // Form  y = alpha * A^T * x + y  or  y = alpha * A^H * x + y.
            var jy: i32 = ky;
            if (incx == 1) {
                var j: i32 = 0;
                while (j < n) : (j += 1) {
                    var temp: C2 = constants.zero(C2, ctx) catch unreachable;
                    if (noconj) {
                        var i: i32 = 0;
                        while (i < m) : (i += 1) {
                            ops.add_( // temp += a[i + j * lda] * x[i]
                                &temp,
                                temp,
                                ops.mul(
                                    a[scast(u32, i + j * lda)],
                                    x[scast(u32, i)],
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;
                        }
                    } else {
                        var i: i32 = 0;
                        while (i < m) : (i += 1) {
                            ops.add_( // temp += conj(a[i + j * lda]) * x[i]
                                &temp,
                                temp,
                                ops.mul(
                                    ops.conj(a[scast(u32, i + j * lda)], ctx) catch unreachable,
                                    x[scast(u32, i)],
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;
                        }
                    }

                    ops.add_( // y[jy] += alpha * temp
                        &y[scast(u32, jy)],
                        y[scast(u32, jy)],
                        ops.mul(
                            alpha,
                            temp,
                            ctx,
                        ) catch unreachable,
                        ctx,
                    ) catch unreachable;

                    jy += incy;
                }
            } else {
                var j: i32 = 0;
                while (j < n) : (j += 1) {
                    var temp: C2 = constants.zero(C2, ctx) catch unreachable;

                    if (noconj) {
                        var ix: i32 = kx;
                        var i: i32 = 0;
                        while (i < m) : (i += 1) {
                            ops.add_( // temp += a[i + j * lda] * x[ix]
                                &temp,
                                temp,
                                ops.mul(
                                    a[scast(u32, i + j * lda)],
                                    x[scast(u32, ix)],
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            ix += incx;
                        }
                    } else {
                        var ix: i32 = kx;
                        var i: i32 = 0;
                        while (i < m) : (i += 1) {
                            ops.add_( // temp += conj(a[i + j * lda]) * x[ix]
                                &temp,
                                temp,
                                ops.mul(
                                    ops.conj(a[scast(u32, i + j * lda)], ctx) catch unreachable,
                                    x[scast(u32, ix)],
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            ix += incx;
                        }
                    }

                    ops.add_( // y[jy] += alpha * temp
                        &y[scast(u32, jy)],
                        y[scast(u32, jy)],
                        ops.mul(
                            alpha,
                            temp,
                            ctx,
                        ) catch unreachable,
                        ctx,
                    ) catch unreachable;

                    jy += incy;
                }
            }
        }
    } else {
        // Arbitrary precision types not supported yet
        @compileError("zml.linalg.blas.gemv not implemented for arbitrary precision types yet");
    }

    return;
}
