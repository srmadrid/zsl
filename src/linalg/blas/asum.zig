const std = @import("std");

const types = @import("../../types.zig");
const Scalar = types.Scalar;
const Child = types.Child;
const ops = @import("../../ops.zig");

const blas = @import("../blas.zig");

/// Computes the sum of magnitudes of the vector elements.
///
/// The `asum` routine computes the sum of the magnitudes of elements of a real
/// vector, or the sum of magnitudes of the real and imaginary parts of elements
/// of a complex vector:
///
/// ```zig
///     abs(x[0].re) + abs(x[0].im) + abs(x[1].re) + abs(x[1].im) + ... + abs(x[n - 1].re) + abs(x[n - 1].im),
/// ```
///
/// where `x` is a vector with `n` elements.
///
/// Signature
/// ---------
/// ```zig
/// fn asum(n: i32, x: [*]const X, incx: i32, ctx: anytype) !Scalar(X)
/// ```
///
/// Parameters
/// ----------
/// `n` (`i32`): Specifies the number of elements in vector `x`. Must be
/// greater than 0.
///
/// `x` (many-item pointer to `int`, `float`, `cfloat`, `integer`, `rational`,
/// `real`, `complex` or `expression`): Array, size at least
/// `1 + (n - 1) * abs(incx)`.
///
/// `incx` (`i32`): Specifies the increment for indexing vector `x`. Must be
/// greater than 0.
///
/// Returns
/// -------
/// `Scalar(Child(@TypeOf(x)))`: The sum of magnitudes of real and imaginary
/// parts of all elements of the vector.
///
/// Errors
/// ------
/// `linalg.blas.Error.InvalidArgument`: If `n` or `incx` is less than or equal
/// to 0.
///
/// Notes
/// -----
/// If the `link_cblas` option is not `null`, the function will try to call the
/// corresponding CBLAS function, if available. In that case, no errors will be
/// raised even if the arguments are invalid.
pub fn asum(
    n: i32,
    x: anytype,
    incx: i32,
    ctx: anytype,
) !Scalar(Child(@TypeOf(x))) {
    comptime var X: type = @TypeOf(x);

    comptime if (!types.isManyPointer(X))
        @compileError("zml.linalg.blas.asum requires x to be a many-item pointer, got " ++ @typeName(X));

    X = types.Child(X);

    comptime if (!types.isNumeric(X) or X == bool)
        @compileError("zml.linalg.blas.asum requires x's child type to be a non bool numeric, got " ++ @typeName(X));

    comptime if (types.isArbitraryPrecision(X)) {
        @compileError("zml.linalg.blas.asum not implemented for arbitrary precision types yet");
    } else {
        types.validateContext(@TypeOf(ctx), .{});
    };

    if (options.link_cblas != null) {
        switch (comptime types.numericType(X)) {
            .float => {
                if (comptime X == f32) {
                    return ci.cblas_sasum(scast(c_int, n), x, scast(c_int, incx));
                } else if (comptime X == f64) {
                    return ci.cblas_dasum(scast(c_int, n), x, scast(c_int, incx));
                }
            },
            .cfloat => {
                if (comptime Scalar(X) == f32) {
                    return ci.cblas_scasum(scast(c_int, n), x, scast(c_int, incx));
                } else if (comptime Scalar(X) == f64) {
                    return ci.cblas_dzasum(scast(c_int, n), x, scast(c_int, incx));
                }
            },
            else => {},
        }
    }

    return _asum(n, x, incx, ctx);
}

fn _asum(
    n: i32,
    x: anytype,
    incx: i32,
    ctx: anytype,
) !Scalar(Child(@TypeOf(x))) {
    const X: type = types.Child(@TypeOf(x));

    var sum: Scalar(X) = try ops.init(Scalar(X), ctx);
    errdefer ops.deinit(&sum, ctx);

    try @import("asum_sub.zig").asum_sub(n, x, incx, &sum, ctx);

    return sum;
}
