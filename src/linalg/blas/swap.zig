const std = @import("std");

const types = @import("../../types.zig");
const scast = types.scast;
const ops = @import("../../ops.zig");

const blas = @import("../blas.zig");

/// Swaps a vector with another vector.
///
/// Given two vectors `x` and `y`, the `swap` routine returns vectors `y` and
/// `x` swapped, each replacing the other.
///
/// Signature
/// ---------
/// ```zig
/// fn swap(n: i32, x: [*]X, incx: i32, y: [*]Y, incy: i32, ctx: anytype) !void
/// ```
///
/// Parameters
/// ----------
/// `n` (`i32`): Specifies the number of elements in vectors `x` and `y`. Must
/// be greater than 0.
///
/// `x` (mutable many-item pointer to `bool`, `int`, `float`, `cfloat`,
/// `integer`, `rational`, `real`, `complex` or `expression`): Array, size at
/// least `1 + (n - 1) * abs(incx)`. On return contains the updated vector `x`.
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
/// `void`: The result is stored in `x` and `y`.
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
pub fn swap(
    n: i32,
    x: anytype,
    incx: i32,
    y: anytype,
    incy: i32,
    ctx: anytype,
) !void {
    comptime var X: type = @TypeOf(x);
    comptime var Y: type = @TypeOf(y);

    comptime if (!types.isManyPointer(X) or types.isConstPointer(X))
        @compileError("zml.linalg.blas.swap requires x to be a mutable many-item pointer, got " ++ @typeName(X));

    X = types.Child(X);

    comptime if (!types.isNumeric(X))
        @compileError("zml.linalg.blas.swap requires x's child type to be numeric, got " ++ @typeName(X));

    comptime if (!types.isManyPointer(Y) or types.isConstPointer(Y))
        @compileError("zml.linalg.blas.swap requires y to be a mutable many-item pointer, got " ++ @typeName(Y));

    Y = types.Child(Y);

    comptime if (!types.isNumeric(Y))
        @compileError("zml.linalg.blas.swap requires y's child type to be numeric, got " ++ @typeName(Y));

    comptime if (types.isArbitraryPrecision(X) or
        types.isArbitraryPrecision(Y))
    {
        // When implemented, expand if
        @compileError("zml.linalg.blas.swap not implemented for arbitrary precision types yet");
    } else {
        types.validateContext(@TypeOf(ctx), .{});
    };

    if (comptime X == Y and options.link_cblas != null) {
        switch (comptime types.numericType(X)) {
            .float => {
                if (comptime X == f32) {
                    return ci.cblas_sswap(scast(c_int, n), x, scast(c_int, incx), y, scast(c_int, incy));
                } else if (comptime X == f64) {
                    return ci.cblas_dswap(scast(c_int, n), x, scast(c_int, incx), y, scast(c_int, incy));
                }
            },
            .cfloat => {
                if (comptime Scalar(X) == f32) {
                    return ci.cblas_cswap(scast(c_int, n), x, scast(c_int, incx), y, scast(c_int, incy));
                } else if (comptime Scalar(X) == f64) {
                    return ci.cblas_zswap(scast(c_int, n), x, scast(c_int, incx), y, scast(c_int, incy));
                }
            },
            else => {},
        }
    }

    return _swap(n, x, incx, y, incy, ctx);
}

fn _swap(
    n: i32,
    x: anytype,
    incx: i32,
    y: anytype,
    incy: i32,
    ctx: anytype,
) !void {
    const X: type = types.Child(@TypeOf(x));
    const Y: type = types.Child(@TypeOf(y));
    const C: type = types.Coerce(X, Y);

    if (n < 0) return blas.Error.InvalidArgument;

    if (n == 0) return;

    if (comptime types.isArbitraryPrecision(C)) {
        @compileError("zml.linalg.blas.scal not implemented for arbitrary precision types yet");
    } else {
        var temp: C = ops.init(C, .{}) catch unreachable;

        var ix: i32 = if (incx < 0) (-n + 1) * incx else 0;
        var iy: i32 = if (incy < 0) (-n + 1) * incy else 0;
        for (0..scast(u32, n)) |_| {
            ops.set( // temp = x[ix]
                &temp,
                x[scast(u32, ix)],
                ctx,
            ) catch unreachable;

            ops.set( // x[ix] = y[iy]
                &x[scast(u32, ix)],
                y[scast(u32, iy)],
                ctx,
            ) catch unreachable;

            ops.set( // y[iy] = temp
                &y[scast(u32, iy)],
                temp,
                ctx,
            ) catch unreachable;

            ix += incx;
            iy += incy;
        }
    }
}
