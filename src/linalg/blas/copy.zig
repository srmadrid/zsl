const std = @import("std");

const types = @import("../../types.zig");
const scast = types.scast;
const ops = @import("../../ops.zig");

const blas = @import("../blas.zig");

/// Copies a vector to another vector.
///
/// The `copy` routine performs a vector-vector operation defined as:
///
/// ```zig
///     y = x,
/// ```
///
/// where `x` and `y` are vectors.
///
/// Signature
/// ---------
/// ```zig
/// fn copy(n: i32, x: [*]const X, incx: i32, y: [*]Y, incy: i32, ctx: anytype) !void
///
/// Parameters
/// ----------
/// `n` (`i32`): Specifies the number of elements in vectors `x` and `y`. Must
/// be greater than 0.
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
pub fn copy(
    n: i32,
    x: anytype,
    incx: i32,
    y: anytype,
    incy: i32,
    ctx: anytype,
) !void {
    comptime var X: type = @TypeOf(x);
    comptime var Y: type = @TypeOf(y);

    comptime if (!types.isManyPointer(X))
        @compileError("zml.linalg.blas.copy requires x to be a many-item pointer, got " ++ @typeName(X));

    X = types.Child(X);

    comptime if (!types.isNumeric(X))
        @compileError("zml.linalg.blas.copy requires x's child type to be numeric, got " ++ @typeName(X));

    comptime if (!types.isManyPointer(Y) or types.isConstPointer(Y))
        @compileError("zml.linalg.blas.copy requires y to be a mutable many-item pointer, got " ++ @typeName(Y));

    Y = types.Child(Y);

    comptime if (!types.isNumeric(Y))
        @compileError("zml.linalg.blas.copy requires y's child type to be numeric, got " ++ @typeName(Y));

    comptime if (types.isArbitraryPrecision(X)) {
        if (types.isArbitraryPrecision(Y)) {
            @compileError("zml.linalg.blas.copy not implemented for arbitrary precision types yet");
        } else {
            @compileError("zml.linalg.blas.copy not implemented for arbitrary precision types yet");
        }
    } else {
        if (types.isArbitraryPrecision(Y)) {
            @compileError("zml.linalg.blas.copy not implemented for arbitrary precision types yet");
        } else {
            types.validateContext(@TypeOf(ctx), .{});
        }
    };

    if (comptime X == Y and options.link_cblas != null) {
        switch (comptime types.numericType(X)) {
            .float => {
                if (comptime X == f32) {
                    return ci.cblas_scopy(scast(c_int, n), x, scast(c_int, incx), y, scast(c_int, incy));
                } else if (comptime X == f64) {
                    return ci.cblas_dcopy(scast(c_int, n), x, scast(c_int, incx), y, scast(c_int, incy));
                }
            },
            .cfloat => {
                if (comptime Scalar(X) == f32) {
                    return ci.cblas_ccopy(scast(c_int, n), x, scast(c_int, incx), y, scast(c_int, incy));
                } else if (comptime Scalar(X) == f64) {
                    return ci.cblas_zcopy(scast(c_int, n), x, scast(c_int, incx), y, scast(c_int, incy));
                }
            },
            else => {},
        }
    }

    return _copy(n, x, incx, y, incy, ctx);
}

fn _copy(
    n: i32,
    x: anytype,
    incx: i32,
    y: anytype,
    incy: i32,
    ctx: anytype,
) !void {
    if (n < 0) return blas.Error.InvalidArgument;

    if (n == 0) return;

    var ix: i32 = if (incx < 0) (-n + 1) * incx else 0;
    var iy: i32 = if (incy < 0) (-n + 1) * incy else 0;
    var i: u32 = 0;
    while (i < n) : (i += 1) {
        try ops.set( // y[iy] = x[ix]
            &y[scast(u32, iy)],
            x[scast(u32, ix)],
            ctx,
        );

        ix += incx;
        iy += incy;
    }
}
