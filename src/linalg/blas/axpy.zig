const std = @import("std");

const types = @import("../../types.zig");
const scast = types.scast;
const ops = @import("../../ops.zig");

const blas = @import("../blas.zig");

/// Computes a vector-scalar product and adds the result to a vector.
///
/// The `axpy` routine performs a vector-vector operation defined as:
///
/// ```zig
///     y = alpha * x + y,
/// ```
///
/// where `alpha` is a scalar, and `x` and `y` are vectors each with `n`
/// elements.
///
/// Signature
/// ---------
/// ```zig
/// fn axpy(n: i32, alpha: Al, x: [*]const X, incx: i32, y: [*]Y, incy: i32, ctx: anytype) !void
/// ```
///
/// Parameters
/// ----------
/// `n` (`i32`): Specifies the number of elements in vectors `x` and `y`. Must
/// be greater than 0.
///
/// `alpha` (`bool`, `int`, `float`, `cfloat`, `integer`, `rational`, `real`,
/// `complex` or `expression`): Specifies the scalar `alpha`.
///
/// `x` (many-item pointer to `bool`, `int`, `float`, `cfloat`, `integer`,
/// `rational`, `real`, `complex` or `expression`): Array, size at least
/// `1 + (n - 1) * abs(incx)`.
///
/// `incx` (`i32`): Specifies the increment for the elements of `x`.
///
/// `y` (mutable many-item pointer to `bool`, `int`, `float`, `cfloat`,
/// `integer`, `rational`, `real`, `complex` or `expression`): Array, size at
/// least `1 + (n - 1) * abs(incy)`. On return contains the updated vector `y`.
///
/// `incy` (`i32`): Specifies the increment for the elements of `y`.
///
/// Returns
/// -------
/// `void`: The result is stored in `y`.
///
/// Errors
/// ------
/// `linalg.blas.Error.InvalidArgument`: If `n` is less than or equal to 0.
///
/// Notes
/// -----
/// If the `link_cblas` option is not `null`, the function will try to call the
/// corresponding CBLAS function, if available. In that case, no errors will be
/// raised even if the arguments are invalid.
pub fn axpy(
    n: i32,
    alpha: anytype,
    x: anytype,
    incx: i32,
    y: anytype,
    incy: i32,
    ctx: anytype,
) !void {
    const Al: type = @TypeOf(alpha);
    comptime var X: type = @TypeOf(x);
    comptime var Y: type = @TypeOf(y);

    comptime if (!types.isNumeric(Al))
        @compileError("zml.linalg.blas.axpy requires alpha to be a numeric type, got " ++ @typeName(Al));

    comptime if (!types.isManyPointer(X))
        @compileError("zml.linalg.blas.axpy requires x to be a many-item pointer, got " ++ @typeName(X));

    X = types.Child(X);
    const C: type = Coerce(Al, X);

    comptime if (!types.isNumeric(X))
        @compileError("zml.linalg.blas.axpy requires x's child type to be numeric, got " ++ @typeName(X));

    comptime if (!types.isManyPointer(Y) or types.isConstPointer(Y))
        @compileError("zml.linalg.blas.axpy requires y to be a mutable many-item pointer, got " ++ @typeName(Y));

    Y = types.Child(Y);

    comptime if (!types.isNumeric(Y))
        @compileError("zml.linalg.blas.axpy requires y's child type to be numeric, got " ++ @typeName(Y));

    comptime if (Al == bool and X == bool and Y == bool)
        @compileError("zml.linalg.blas.axpy does not support alpha, x and y all being bool");

    comptime if (types.isArbitraryPrecision(C)) {
        if (types.isArbitraryPrecision(Y)) {
            @compileError("zml.linalg.blas.axpy not implemented for arbitrary precision types yet");
        } else {
            @compileError("zml.linalg.blas.axpy not implemented for arbitrary precision types yet");
        }
    } else {
        if (types.isArbitraryPrecision(Y)) {
            @compileError("zml.linalg.blas.axpy not implemented for arbitrary precision types yet");
        } else {
            types.validateContext(@TypeOf(ctx), .{});
        }
    };

    if (comptime X == Y and types.canCoerce(Al, X) and options.link_cblas != null) {
        switch (comptime types.numericType(X)) {
            .float => {
                if (comptime X == f32) {
                    return ci.cblas_saxpy(scast(c_int, n), scast(X, alpha), x, scast(c_int, incx), y, scast(c_int, incy));
                } else if (comptime X == f64) {
                    return ci.cblas_daxpy(scast(c_int, n), scast(X, alpha), x, scast(c_int, incx), y, scast(c_int, incy));
                }
            },
            .cfloat => {
                if (comptime Scalar(X) == f32) {
                    const alpha_casted: X = scast(X, alpha);
                    return ci.cblas_caxpy(scast(c_int, n), &alpha_casted, x, scast(c_int, incx), y, scast(c_int, incy));
                } else if (comptime Scalar(X) == f64) {
                    const alpha_casted: X = scast(X, alpha);
                    return ci.cblas_zaxpy(scast(c_int, n), &alpha_casted, x, scast(c_int, incx), y, scast(c_int, incy));
                }
            },
            else => {},
        }
    }

    return _axpy(n, alpha, x, incx, y, incy, ctx);
}

fn _axpy(
    n: i32,
    alpha: anytype,
    x: anytype,
    incx: i32,
    y: anytype,
    incy: i32,
    ctx: anytype,
) !void {
    const Al: type = @TypeOf(alpha);
    const X: type = types.Child(@TypeOf(x));
    const C: type = types.Coerce(Al, X);
    const Y: type = types.Child(@TypeOf(y));

    if (n <= 0) return blas.Error.InvalidArgument;

    if (ops.eq(alpha, 0, .{}) catch unreachable) return;

    var ix: i32 = if (incx < 0) (-n + 1) * incx else 0;
    var iy: i32 = if (incy < 0) (-n + 1) * incy else 0;
    if (comptime types.isArbitraryPrecision(C)) {
        if (comptime types.isArbitraryPrecision(Y)) {
            // Orientative implementation for arbitrary precision types
            var temp: C = try ops.init(C, ctx);
            defer ops.deinit(temp, ctx);
            for (0..scast(u32, n)) |_| {
                try ops.mul_(
                    &temp,
                    alpha,
                    x[scast(u32, ix)],
                    ctx,
                );

                try ops.add_(
                    &y[scast(u32, iy)],
                    y[scast(u32, iy)],
                    temp,
                    ctx,
                );

                ix += incx;
                iy += incy;
            }

            @compileError("zml.linalg.blas.axpy not implemented for arbitrary precision types yet");
        } else {
            @compileError("zml.linalg.blas.axpy not implemented for arbitrary precision types yet");
        }
    } else {
        if (comptime types.isArbitraryPrecision(Y)) {
            @compileError("zml.linalg.blas.axpy not implemented for arbitrary precision types yet");
        } else {
            for (0..scast(u32, n)) |_| {
                ops.add_( // y[iy] += alpha * x[ix]
                    &y[scast(u32, iy)],
                    y[scast(u32, iy)],
                    ops.mul(
                        alpha,
                        x[scast(u32, ix)],
                        ctx,
                    ) catch unreachable,
                    ctx,
                ) catch unreachable;

                ix += incx;
                iy += incy;
            }
        }
    }
}
