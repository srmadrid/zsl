const std = @import("std");

const types = @import("../../types.zig");
const scast = types.scast;
const ops = @import("../../ops.zig");

const blas = @import("../blas.zig");

/// Computes the product of a vector by a scalar.
///
/// The `scal` routine performs a vector operation defined as:
///
/// ```zig
///     x = alpha * x,
/// ```
///
/// where `alpha` is a scalar, and `x` is an `n`-element vector.
///
/// Signature
/// ---------
/// ```zig
/// fn scal(n: i32, alpha: Al, x: [*]X, incx: i32, ctx: anytype) !void
/// ```
///
/// Parameters
/// ----------
/// `n` (`i32`): Specifies the number of elements in vector `x`. Must be
/// greater than 0.
///
/// `alpha` (`bool`, `int`, `float`, `cfloat`, `integer`, `rational`, `real`,
/// `complex` or `expression`): Specifies the scalar `alpha`.
///
/// `x` (mutable many-item pointer to `bool`, `int`, `float`, `cfloat`,
/// `integer`, `rational`, `real`, `complex` or `expression`): Array, size at
/// least `1 + (n - 1) * abs(incx)`. On return contains the updated vector `x`.
///
/// `incx` (`i32`): Specifies the increment for the elements of `x`.
///
/// Returns
/// -------
/// `void`: The result is stored in `x`.
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
pub fn scal(
    n: i32,
    alpha: anytype,
    x: anytype,
    incx: i32,
    ctx: anytype,
) !void {
    const Al: type = @TypeOf(alpha);
    comptime var X: type = @TypeOf(x);

    comptime if (!types.isNumeric(Al))
        @compileError("zml.linalg.blas.scal requires alpha to be a numeric type, got " ++ @typeName(Al));

    comptime if (!types.isManyPointer(X) or types.isConstPointer(X))
        @compileError("zml.linalg.blas.scal requires x to be a mutable many-item pointer, got " ++ @typeName(X));

    X = types.Child(X);

    comptime if (!types.isNumeric(X))
        @compileError("zml.linalg.blas.scal requires x's child type to be numeric, got " ++ @typeName(X));

    comptime if (Al == bool and X == bool)
        @compileError("zml.linalg.blas.scal does not support alpha and x both being bool");

    comptime if (types.isArbitraryPrecision(Al) or types.isArbitraryPrecision(X)) {
        // When implemented, expand if
        @compileError("zml.linalg.blas.scal not implemented for arbitrary precision types yet");
    } else {
        types.validateContext(@TypeOf(ctx), .{});
    };

    if (comptime types.canCoerce(Al, X) and options.link_cblas != null) {
        switch (comptime types.numericType(X)) {
            .float => {
                if (comptime X == f32) {
                    return ci.cblas_sscal(scast(c_int, n), scast(X, alpha), x, scast(c_int, incx));
                } else if (comptime X == f64) {
                    return ci.cblas_dscal(scast(c_int, n), scast(X, alpha), x, scast(c_int, incx));
                }
            },
            .cfloat => {
                if (comptime types.isComplex(Al)) {
                    if (comptime Scalar(X) == f32) {
                        const alpha_casted: X = scast(X, alpha);
                        return ci.cblas_cscal(scast(c_int, n), &alpha_casted, x, scast(c_int, incx));
                    } else if (comptime Scalar(X) == f64) {
                        const alpha_casted: X = scast(X, alpha);
                        return ci.cblas_zscal(scast(c_int, n), &alpha_casted, x, scast(c_int, incx));
                    }
                } else {
                    if (comptime Scalar(X) == f32) {
                        return ci.cblas_csscal(scast(c_int, n), scast(Scalar(X), alpha), x, scast(c_int, incx));
                    } else if (comptime Scalar(X) == f64) {
                        return ci.cblas_zdscal(scast(c_int, n), scast(Scalar(X), alpha), x, scast(c_int, incx));
                    }
                }
            },
            else => {},
        }
    }

    return _scal(n, alpha, x, incx, ctx);
}

fn _scal(
    n: i32,
    alpha: anytype,
    x: anytype,
    incx: i32,
    ctx: anytype,
) !void {
    const Al: type = @TypeOf(alpha);
    const X: type = types.Child(@TypeOf(x));
    const C: type = types.Coerce(Al, X);

    if (n < 0 or incx <= 0) return blas.Error.InvalidArgument;

    if (n == 0) return;

    if (ops.eq(alpha, 1, .{}) catch unreachable) return;

    if (comptime types.isArbitraryPrecision(C)) {
        @compileError("zml.linalg.blas.scal not implemented for arbitrary precision types yet");
    } else {
        var ix: i32 = 0;
        for (0..scast(u32, n)) |_| {
            ops.mul_( // x[ix] *= alpha
                &x[scast(u32, ix)],
                x[scast(u32, ix)],
                alpha,
                ctx,
            ) catch unreachable;

            ix += incx;
        }
    }
}
