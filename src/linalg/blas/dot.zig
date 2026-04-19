const std = @import("std");

const types = @import("../../types.zig");
const Child = types.Child;
const Coerce = types.Coerce;
const ops = @import("../../ops.zig");

const blas = @import("../blas.zig");

/// Computes a vector-vector dot product.
///
/// The `dot` routine performs a vector-vector reduction operation defined
/// as:
///
/// ```zig
///     x[0] * y[0] + x[1] * y[1] + ... + x[n - 1] * y[n - 1],
/// ```
///
/// where `x` and `y` are vectors.
///
/// Signature
/// ---------
/// ```zig
/// fn dot(n: i32, x: [*]const X, incx: i32, y: [*]const Y, incy: i32, ctx: anytype) !Coerce(X, Y)
/// ```
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
/// `Scalar(Coerce(Child(@TypeOf(x)), Child(@TypeOf(y))))`: The result of the
/// dot product.
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
pub fn dot(
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
        @compileError("zml.linalg.blas.dot requires x to be a many-item pointer, got " ++ @typeName(X));

    X = types.Child(X);

    comptime if (!types.isNumeric(X))
        @compileError("zml.linalg.blas.dot requires x's child type to be numeric, got " ++ @typeName(X));

    comptime if (!types.isManyPointer(Y))
        @compileError("zml.linalg.blas.dot requires y to be a many-item pointer, got " ++ @typeName(Y));

    Y = types.Child(Y);
    const C: type = Coerce(X, Y);

    comptime if (!types.isNumeric(Y))
        @compileError("zml.linalg.blas.dot requires y's child type to be numeric, got " ++ @typeName(Y));

    comptime if (X == bool and Y == bool)
        @compileError("zml.linalg.blas.dot does not support x and y both being bool");

    comptime if (types.isArbitraryPrecision(C)) {
        @compileError("zml.linalg.blas.dot not implemented for arbitrary precision types yet");
    } else {
        types.validateContext(@TypeOf(ctx), .{});
    };

    if (comptime X == Y and options.link_cblas != null) {
        switch (comptime types.numericType(X)) {
            .float => {
                if (comptime X == f32) {
                    return ci.cblas_sdot(scast(c_int, n), x, scast(c_int, incx), y, scast(c_int, incy));
                } else if (comptime X == f64) {
                    return ci.cblas_ddot(scast(c_int, n), x, scast(c_int, incx), y, scast(c_int, incy));
                }
            },
            else => {},
        }
    }

    return _dot(n, x, incx, y, incy, ctx);
}

fn _dot(
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

    try @import("dot_sub.zig").dot_sub(n, x, incx, y, incy, &sum, ctx);

    return sum;
}
