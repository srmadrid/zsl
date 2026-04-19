const std = @import("std");

const types = @import("../../types.zig");
const scast = types.scast;
const ops = @import("../../ops.zig");
const constants = @import("../../constants.zig");

const linalg = @import("../../linalg.zig");
const blas = @import("../blas.zig");
const Order = types.Order;
const Uplo = types.Uplo;

/// Performs a rank-2 update of a symmetric packed matrix.
///
/// The `spr2` routine performs a matrix-vector operation defined as:
///
/// ```zig
///     A = alpha * x * y^T + alpha * y * x^T + A,
/// ```
///
/// where `alpha` is a scalar, `x` and `y` are `n`-element vectors, and `A` is
/// an `n`-by-`n` symmetric matrix, supplied in packed form.
///
/// Signature
/// ---------
/// ```zig
/// fn spr2(order: Order, uplo: Uplo, n: i32, alpha: Al, x: [*]const X, incx: i32, y: [*]const Y, incy: i32, ap: [*]A, ctx: anytype) !void
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
/// `x` (many-item pointer to `int`, `float`, `cfloat`, `integer`, `rational`,
/// `real`, `complex` or `expression`): Array, size at least
/// `1 + (n - 1) * abs(incx)`.
///
/// `incx` (`i32`): Specifies the increment for indexing vector `x`. Must be
/// different from 0.
///
/// `y` (many-item pointer to `int`, `float`, `cfloat`, `integer`, `rational`,
/// `real`, `complex` or `expression`): Array, size at least
/// `1 + (n - 1) * abs(incy)`.
///
/// `incy` (`i32`): Specifies the increment for indexing vector `y`. Must be
/// different from 0.
///
/// `ap` (mutable many-item pointer to `int`, `float`, `cfloat`, `integer`,
/// `rational`, `real`, `complex` or `expression`): Array, size at least
/// `(n * (n + 1)) / 2`. On return, contains the result of the operation.
///
/// Returns
/// -------
/// `void`: The result is stored in `ap`.
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
pub fn spr2(
    order: Layout,
    uplo: Uplo,
    n: i32,
    alpha: anytype,
    x: anytype,
    incx: i32,
    y: anytype,
    incy: i32,
    ap: anytype,
    ctx: anytype,
) !void {
    const Al: type = @TypeOf(alpha);
    comptime var X: type = @TypeOf(x);
    comptime var Y: type = @TypeOf(y);
    comptime var A: type = @TypeOf(ap);

    comptime if (!types.isNumeric(Al))
        @compileError("zml.linalg.blas.spr2 requires alpha to be numeric, got " ++ @typeName(Al));

    comptime if (!types.isManyPointer(X))
        @compileError("zml.linalg.blas.spr2 requires x to be a many-item pointer, got " ++ @typeName(X));

    X = types.Child(X);

    comptime if (!types.isNumeric(X))
        @compileError("zml.linalg.blas.spr2 requires x's child type to be numeric, got " ++ @typeName(X));

    comptime if (!types.isManyPointer(Y))
        @compileError("zml.linalg.blas.spr2 requires y to be a many-item pointer, got " ++ @typeName(Y));

    Y = types.Child(Y);

    comptime if (!types.isNumeric(Y))
        @compileError("zml.linalg.blas.spr2 requires y's child type to be numeric, got " ++ @typeName(Y));

    comptime if (!types.isManyPointer(A) or types.isConstPointer(A))
        @compileError("zml.linalg.blas.spr2 requires a to be a mutable many-item pointer, got " ++ @typeName(A));

    A = types.Child(A);

    comptime if (!types.isNumeric(A))
        @compileError("zml.linalg.blas.spr2 requires a's child type to numeric, got " ++ @typeName(A));

    comptime if (Al == bool and X == bool and Y == bool and A == bool)
        @compileError("zml.linalg.blas.spr2 does not support alpha, a, x, beta and y all being bool");

    comptime if (types.isArbitraryPrecision(Al) or
        types.isArbitraryPrecision(X) or
        types.isArbitraryPrecision(Y) or
        types.isArbitraryPrecision(A))
    {
        // When implemented, expand if
        @compileError("zml.linalg.blas.spr2 not implemented for arbitrary precision types yet");
    } else {
        types.validateContext(@TypeOf(ctx), .{});
    };

    if (comptime A == X and A == Y and types.canCoerce(Al, A) and options.link_cblas != null) {
        switch (comptime types.numericType(A)) {
            .float => {
                if (comptime A == f32) {
                    return ci.cblas_sspr2(order.toCUInt(), uplo.toCUInt(), scast(c_int, n), scast(A, alpha), x, scast(c_int, incx), y, scast(c_int, incy), ap);
                } else if (comptime A == f64) {
                    return ci.cblas_dspr2(order.toCUInt(), uplo.toCUInt(), scast(c_int, n), scast(A, alpha), x, scast(c_int, incx), y, scast(c_int, incy), ap);
                }
            },
            else => {},
        }
    }

    return _spr2(order, uplo, n, alpha, x, incx, y, incy, ap, ctx);
}

fn _spr2(
    order: Order,
    uplo: Uplo,
    n: i32,
    alpha: anytype,
    x: anytype,
    incx: i32,
    y: anytype,
    incy: i32,
    ap: anytype,
    ctx: anytype,
) !void {
    if (order == .col_major) {
        return k_spr2(uplo, n, alpha, x, incx, y, incy, ap, ctx);
    } else {
        return k_spr2(uplo.invert(), n, alpha, y, incy, x, incx, ap, ctx);
    }
}

fn k_spr2(
    uplo: Uplo,
    n: i32,
    alpha: anytype,
    x: anytype,
    incx: i32,
    y: anytype,
    incy: i32,
    ap: anytype,
    ctx: anytype,
) !void {
    const Al: type = @TypeOf(alpha);
    const X: type = types.Child(@TypeOf(x));
    const C2: type = types.Coerce(Al, X);
    const Y: type = types.Child(@TypeOf(y));
    const C1: type = types.Coerce(Al, Y);
    const A: type = types.Child(@TypeOf(ap));
    const CC: type = types.Coerce(Al, types.Coerce(X, types.Coerce(Y, A)));

    if (n < 0 or incx == 0 or incy == 0)
        return blas.Error.InvalidArgument;

    // Quick return if possible.
    if (n == 0 or ops.eq(alpha, 0, ctx) catch unreachable)
        return;

    const kx: i32 = if (incx < 0) (-n + 1) * incx else 0;
    const ky: i32 = if (incy < 0) (-n + 1) * incy else 0;

    if (comptime !types.isArbitraryPrecision(CC)) {
        var kk: i32 = 0;
        if (uplo == .upper) {
            if (incx == 1 and incy == 1) {
                var j: i32 = 0;
                while (j < n) : (j += 1) {
                    if (ops.ne(x[scast(u32, j)], 0, ctx) catch unreachable or
                        ops.ne(y[scast(u32, j)], 0, ctx) catch unreachable)
                    {
                        const temp1: C1 = ops.mul( // temp1 = alpha * y[j]
                            y[scast(u32, j)],
                            alpha,
                            ctx,
                        ) catch unreachable;
                        const temp2: C2 = ops.mul( // temp2 = alpha * x[j]
                            x[scast(u32, j)],
                            alpha,
                            ctx,
                        ) catch unreachable;

                        var k: i32 = kk;
                        var i: i32 = 0;
                        while (i < j) : (i += 1) {
                            ops.add_( // ap[k] += x[i] * temp1 + y[i] * temp2
                                &ap[scast(u32, k)],
                                ap[scast(u32, k)],
                                ops.add(
                                    ops.mul(
                                        x[scast(u32, i)],
                                        temp1,
                                        ctx,
                                    ) catch unreachable,
                                    ops.mul(
                                        y[scast(u32, i)],
                                        temp2,
                                        ctx,
                                    ) catch unreachable,
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            k += 1;
                        }

                        ops.add_( // ap[kk + j] += x[j] * temp1 + y[j] * temp2
                            &ap[scast(u32, kk + j)],
                            ap[scast(u32, kk + j)],
                            ops.add(
                                ops.mul(
                                    x[scast(u32, j)],
                                    temp1,
                                    ctx,
                                ) catch unreachable,
                                ops.mul(
                                    y[scast(u32, j)],
                                    temp2,
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable,
                            ctx,
                        ) catch unreachable;
                    }

                    kk += j + 1;
                }
            } else {
                var jx: i32 = kx;
                var jy: i32 = ky;
                var j: i32 = 0;
                while (j < n) : (j += 1) {
                    if (ops.ne(x[scast(u32, jx)], 0, ctx) catch unreachable or
                        ops.ne(y[scast(u32, jy)], 0, ctx) catch unreachable)
                    {
                        const temp1: C1 = ops.mul( // temp1 = alpha * y[jy]
                            y[scast(u32, jy)],
                            alpha,
                            ctx,
                        ) catch unreachable;
                        const temp2: C2 = ops.mul( // temp2 = alpha * x[jx]
                            x[scast(u32, jx)],
                            alpha,
                            ctx,
                        ) catch unreachable;

                        var ix: i32 = kx;
                        var iy: i32 = ky;
                        var k: i32 = kk;
                        while (k < kk + j) : (k += 1) {
                            ops.add_( // ap[k] += x[ix] * temp1 + y[iy] * temp2
                                &ap[scast(u32, k)],
                                ap[scast(u32, k)],
                                ops.add(
                                    ops.mul(
                                        x[scast(u32, ix)],
                                        temp1,
                                        ctx,
                                    ) catch unreachable,
                                    ops.mul(
                                        y[scast(u32, iy)],
                                        temp2,
                                        ctx,
                                    ) catch unreachable,
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;

                            ix += incx;
                            iy += incy;
                        }

                        ops.add_( // ap[kk + j] += x[jx] * temp1 + y[jy] * temp2
                            &ap[scast(u32, kk + j)],
                            ap[scast(u32, kk + j)],
                            ops.add(
                                ops.mul(
                                    x[scast(u32, jx)],
                                    temp1,
                                    ctx,
                                ) catch unreachable,
                                ops.mul(
                                    y[scast(u32, jy)],
                                    temp2,
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable,
                            ctx,
                        ) catch unreachable;
                    }

                    jx += incx;
                    jy += incy;
                    kk += j + 1;
                }
            }
        } else {
            if (incx == 1 and incy == 1) {
                var j: i32 = 0;
                while (j < n) : (j += 1) {
                    if (ops.ne(x[scast(u32, j)], 0, ctx) catch unreachable or
                        ops.ne(y[scast(u32, j)], 0, ctx) catch unreachable)
                    {
                        const temp1: C1 = ops.mul( // temp1 = alpha * y[j]
                            y[scast(u32, j)],
                            alpha,
                            ctx,
                        ) catch unreachable;
                        const temp2: C2 = ops.mul( // temp2 = alpha * x[j]
                            x[scast(u32, j)],
                            alpha,
                            ctx,
                        ) catch unreachable;

                        ops.add_( // ap[kk] += x[j] * temp1 + y[j] * temp2
                            &ap[scast(u32, kk)],
                            ap[scast(u32, kk)],
                            ops.add(
                                ops.mul(
                                    x[scast(u32, j)],
                                    temp1,
                                    ctx,
                                ) catch unreachable,
                                ops.mul(
                                    y[scast(u32, j)],
                                    temp2,
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable,
                            ctx,
                        ) catch unreachable;

                        var k: i32 = kk + 1;
                        var i: i32 = j + 1;
                        while (i < n) : (i += 1) {
                            ops.add_( // ap[k] += x[i] * temp1 + y[i] * temp2
                                &ap[scast(u32, k)],
                                ap[scast(u32, k)],
                                ops.add(
                                    ops.mul(
                                        x[scast(u32, i)],
                                        temp1,
                                        ctx,
                                    ) catch unreachable,
                                    ops.mul(
                                        y[scast(u32, i)],
                                        temp2,
                                        ctx,
                                    ) catch unreachable,
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
                var jy: i32 = ky;
                var j: i32 = 0;
                while (j < n) : (j += 1) {
                    if (ops.ne(x[scast(u32, jx)], 0, ctx) catch unreachable or
                        ops.ne(y[scast(u32, jy)], 0, ctx) catch unreachable)
                    {
                        const temp1: C1 = ops.mul( // temp1 = alpha * y[jy]
                            y[scast(u32, jy)],
                            alpha,
                            ctx,
                        ) catch unreachable;
                        const temp2: C2 = ops.mul( // temp2 = alpha * x[jx]
                            x[scast(u32, jx)],
                            alpha,
                            ctx,
                        ) catch unreachable;

                        ops.add_( // ap[kk] += x[jx] * temp1 + y[jy] * temp2
                            &ap[scast(u32, kk)],
                            ap[scast(u32, kk)],
                            ops.add(
                                ops.mul(
                                    x[scast(u32, jx)],
                                    temp1,
                                    ctx,
                                ) catch unreachable,
                                ops.mul(
                                    y[scast(u32, jy)],
                                    temp2,
                                    ctx,
                                ) catch unreachable,
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

                            ops.add_( // ap[k] += x[ix] * temp1 + y[iy] * temp2
                                &ap[scast(u32, k)],
                                ap[scast(u32, k)],
                                ops.add(
                                    ops.mul(
                                        x[scast(u32, ix)],
                                        temp1,
                                        ctx,
                                    ) catch unreachable,
                                    ops.mul(
                                        y[scast(u32, iy)],
                                        temp2,
                                        ctx,
                                    ) catch unreachable,
                                    ctx,
                                ) catch unreachable,
                                ctx,
                            ) catch unreachable;
                        }
                    }

                    jx += incx;
                    jy += incy;
                    kk += n - j;
                }
            }
        }
    } else {
        // Arbitrary precision types not supported yet
        @compileError("zml.linalg.blas.spr2 not implemented for arbitrary precision types yet");
    }

    return;
}
