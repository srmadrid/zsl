const std = @import("std");

const types = @import("../../types.zig");
const Child = types.Child;
const Coerce = types.Coerce;
const ops = @import("../../ops.zig");

const blas = @import("../blas.zig");

/// Computes a dot product of a conjugated vector with another vector.
///
/// The `dotc` routine performs a vector-vector operation defined as:
///
/// ```zig
///     conj(x[0]) * y[0] + conj(x[1]) * y[1] + ... + conj(x[n - 1]) * y[n - 1],
/// ```
///
/// where `x` and `y` are vectors.
///
/// Signature
/// ---------
/// ```zig
/// fn dotc(n: i32, x: [*]const X, incx: i32, y: [*]const Y, incy: i32, ctx: anytype) !Coerce(X, Y)
///
/// Parameters
/// ----------
/// `n` (`i32`): Specifies the number of elements in vectors `x` and `y`. Must
/// be greater than 0.
///
/// `x` (many-item pointer to `bool`, `int`, `float`, `cfloat` `integer`,
/// `rational`, `real`, `complex` or `expression`): Array, size at least
/// `1 + (n - 1) * abs(incx)`.
///
/// `incx` (`i32`): Specifies the increment for the elements of `x`.
///
/// `y` (many-item pointer to `bool`, `int`, `float`, `cfloat` `integer`,
/// `rational`, `real`, `complex` or `expression`): Array, size at least
/// `1 + (n - 1) * abs(incy)`.
///
/// `incy` (`i32`): Specifies the increment for the elements of `y`.
///
/// Returns
/// -------
/// `Coerce(Child(@TypeOf(x)), Child(@TypeOf(y)))`: The result of the dot
/// product.
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
pub fn dotc(
    n: i32,
    x: anytype,
    incx: i32,
    y: anytype,
    incy: i32,
    ctx: anytype,
) !Coerce(Child(@TypeOf(x)), Child(@TypeOf(y))) {
    comptime var X: type = @TypeOf(x);
    comptime var Y: type = @TypeOf(y);

    comptime if (!types.isManyPointer(X))
        @compileError("zml.linalg.blas.dotc requires x to be a many-item pointer, got " ++ @typeName(X));

    X = types.Child(X);

    comptime if (!types.isNumeric(X))
        @compileError("zml.linalg.blas.dotc requires x's child type to be numeric, got " ++ @typeName(X));

    comptime if (!types.isManyPointer(Y))
        @compileError("zml.linalg.blas.dotc requires y to be a many-item pointer, got " ++ @typeName(Y));

    Y = types.Child(Y);
    const C: type = Coerce(X, Y);

    comptime if (!types.isNumeric(Y))
        @compileError("zml.linalg.blas.dotc requires y's child type to be numeric, got " ++ @typeName(Y));

    comptime if (X == bool and Y == bool)
        @compileError("zml.linalg.blas.dotc does not support x and y both being bool");

    comptime if (types.isArbitraryPrecision(C)) {
        @compileError("zml.linalg.blas.dotc not implemented for arbitrary precision types yet");
    } else {
        types.validateContext(@TypeOf(ctx), .{});
    };

    if (comptime X == Y and options.link_cblas != null) {
        switch (comptime types.numericType(X)) {
            .cfloat => {
                if (comptime Scalar(X) == f32) {
                    var temp: cf32 = undefined;
                    ci.cblas_cdotc_sub(scast(c_int, n), x, scast(c_int, incx), y, scast(c_int, incy), &temp);
                    return temp;
                } else if (comptime Scalar(X) == f64) {
                    var temp: cf64 = undefined;
                    ci.cblas_zdotc_sub(scast(c_int, n), x, scast(c_int, incx), y, scast(c_int, incy), &temp);
                    return temp;
                }
            },
            else => {},
        }
    }

    return _dotc(n, x, incx, y, incy, ctx);
}

fn _dotc(
    n: i32,
    x: anytype,
    incx: i32,
    y: anytype,
    incy: i32,
    ctx: anytype,
) !Coerce(Child(@TypeOf(x)), Child(@TypeOf(y))) {
    const X: type = types.Child(@TypeOf(x));
    const Y: type = types.Child(@TypeOf(y));
    const C: type = types.Coerce(X, Y);

    var sum: C = try ops.init(C, ctx);
    errdefer ops.deinit(&sum, ctx);

    try @import("dotc_sub.zig").dotc_sub(n, x, incx, y, incy, &sum, ctx);

    return sum;
}
