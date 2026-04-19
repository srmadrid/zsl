const std = @import("std");

const types = @import("../../types.zig");
const scast = types.scast;
const Scalar = types.Scalar;
const ops = @import("../../ops.zig");
const float = @import("../../float.zig");

const blas = @import("../blas.zig");

/// Finds the index of the element with the smallest absolute value.
///
/// Given a vector `x`, the `iamin` routine returns the position of the vector
/// element `x[i]` that has the smallest absolute value for real vectors, or the
/// smallest sum `|x[i].re| + |x[i].im|` for complex vectors.
///
/// If more than one vector element is found with the same smallest absolute
/// value, the index of the first one encountered is returned.
///
/// Signature
/// ---------
/// ```zig
/// fn iamin(n: i32, x: [*]const X, incx: i32, ctx: anytype) !u32
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
/// `u32`: The index of the element with the smallest absolute value in `x`.
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
pub fn iamin(
    n: i32,
    x: anytype,
    incx: i32,
    ctx: anytype,
) !u32 {
    comptime var X: type = @TypeOf(x);

    comptime if (!types.isManyPointer(X))
        @compileError("zml.linalg.blas.iamin requires x to be a many-item pointer, got " ++ @typeName(X));

    X = types.Child(X);

    comptime if (!types.isNumeric(X) or X == bool)
        @compileError("zml.linalg.blas.iamin requires x's child type to be a non bool numeric, got " ++ @typeName(X));

    comptime if (types.isArbitraryPrecision(X)) {
        // When implemented, expand if
        // Might need but only when arbitrary p complex
        @compileError("zml.linalg.blas.iamin not implemented for arbitrary precision types yet");
    } else {
        types.validateContext(@TypeOf(ctx), .{});
    };

    if (comptime options.link_cblas != null) {
        switch (comptime types.numericType(X)) {
            .float => {
                if (comptime X == f32) {
                    return types.scast(u32, ci.cblas_isamin(scast(c_int, n), x, scast(c_int, incx)));
                } else if (comptime X == f64) {
                    return types.scast(u32, ci.cblas_idamin(scast(c_int, n), x, scast(c_int, incx)));
                }
            },
            .cfloat => {
                if (comptime Scalar(X) == f32) {
                    return types.scast(u32, ci.cblas_icamin(scast(c_int, n), x, scast(c_int, incx)));
                } else if (comptime Scalar(X) == f64) {
                    return types.scast(u32, ci.cblas_izamin(scast(c_int, n), x, scast(c_int, incx)));
                }
            },
            else => {},
        }
    }

    return _iamin(n, x, incx, ctx);
}

fn _iamin(
    n: i32,
    x: anytype,
    incx: i32,
    ctx: anytype,
) !u32 {
    const X: type = types.Child(@TypeOf(x));

    if (n <= 0 or incx <= 0) return blas.Error.InvalidArgument;

    if (n == 1) return 0;

    var imin: u32 = 0;

    if (comptime !types.isArbitraryPrecision(X)) {
        if (comptime !types.isComplex(X)) {
            var min: X = ops.abs(x[0], ctx) catch unreachable;
            var ix: i32 = if (incx < 0) (-n + 2) * incx else incx;
            for (1..scast(u32, n)) |i| {
                const absx: X = ops.abs(x[scast(u32, ix)], ctx) catch unreachable;
                if (ops.lt(absx, min, ctx) catch unreachable) {
                    min = absx;
                    imin = scast(u32, i);
                }

                ix += incx;
            }
        } else {
            var min: Scalar(X) = ops.add(
                ops.abs(x[0].re, ctx) catch unreachable,
                ops.abs(x[0].im, ctx) catch unreachable,
                ctx,
            ) catch unreachable;
            var ix: i32 = if (incx < 0) (-n + 2) * incx else incx;
            for (1..scast(u32, n)) |i| {
                const absx: Scalar(X) = ops.add(
                    ops.abs(x[scast(u32, ix)].re, ctx) catch unreachable,
                    ops.abs(x[scast(u32, ix)].im, ctx) catch unreachable,
                    ctx,
                ) catch unreachable;
                if (ops.lt(absx, min, ctx) catch unreachable) {
                    min = absx;
                    imin = scast(u32, i);
                }

                ix += incx;
            }
        }
    } else {
        // On abs, copy = false
        @compileError("zml.linalg.blas.iamin not implemented for arbitrary precision types yet");
    }

    return imin;
}
