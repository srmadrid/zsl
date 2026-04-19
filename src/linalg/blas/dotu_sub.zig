const std = @import("std");

const types = @import("../../types.zig");
const scast = types.scast;
const ops = @import("../../ops.zig");
const float = @import("../../float.zig");

const blas = @import("../blas.zig");

/// Computes a vector-vector dot product.
///
/// The `dotu_sub` routine performs a vector-vector reduction operation defined
/// as:
///
/// ```zig
///     ret = x[0] * y[0] + x[1] * y[1] + ... + x[n - 1] * y[n - 1],
/// ```
///
/// where `x` and `y` are vectors.
///
/// Signature
/// ---------
/// ```zig
/// fn dotu_sub(n: i32, x: [*]const X, incx: i32, y: [*]const Y, incy: i32, ret: *R, ctx: anytype) !void
/// ```
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
/// `y` (many-item pointer to `bool`, `int`, `float`, `cfloat`, `integer`,
/// `rational`, `real`, `complex` or `expression`): Array, size at least
/// `1 + (n - 1) * abs(incy)`.
///
/// `incy` (`i32`): Specifies the increment for the elements of `y`.
///
/// `ret` (mutable one-item pointer to `bool`, `int`, `float`, `cfloat`,
/// `integer`, `rational`, `real`, `complex` or `expression`): Pointer to where
/// the result will be stored.
///
/// Returns
/// -------
/// `void`: The result is stored in `ret`.
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
pub fn dotu_sub(
    n: i32,
    x: anytype,
    incx: i32,
    y: anytype,
    incy: i32,
    ret: anytype,
    ctx: anytype,
) !void {
    comptime var X: type = @TypeOf(x);
    comptime var Y: type = @TypeOf(y);
    comptime var R: type = @TypeOf(ret);

    comptime if (!types.isManyPointer(X))
        @compileError("zml.linalg.blas.dotu_sub requires x to be a many-item pointer, got " ++ @typeName(X));

    X = types.Child(X);

    comptime if (!types.isNumeric(X))
        @compileError("zml.linalg.blas.dotu_sub requires x's child type to be numeric, got " ++ @typeName(X));

    comptime if (!types.isManyPointer(Y))
        @compileError("zml.linalg.blas.dotu_sub requires y to be a many-item pointer, got " ++ @typeName(Y));

    Y = types.Child(Y);
    const C: type = Coerce(X, Y);

    comptime if (!types.isNumeric(Y))
        @compileError("zml.linalg.blas.dotu_sub requires y's child type to be numeric, got " ++ @typeName(Y));

    comptime if (X == bool and Y == bool)
        @compileError("zml.linalg.blas.dotu_sub does not support x and y both being bool");

    comptime if (!types.isPointer(R) or types.isConstPointer(R))
        @compileError("zml.linalg.blas.dotu_sub requires ret to be a mutable one-item pointer, got " ++ @typeName(R));

    R = types.Child(R);

    comptime if (!types.isNumeric(R))
        @compileError("zml.linalg.blas.dotu_sub requires ret's child type to be numeric, got " ++ @typeName(R));

    comptime if (types.isArbitraryPrecision(R)) {
        if (types.isArbitraryPrecision(C)) {
            @compileError("zml.linalg.blas.dotu_sub not implemented for arbitrary precision types yet");
        } else {
            @compileError("zml.linalg.blas.dotu_sub not implemented for arbitrary precision types yet");
        }
    } else {
        if (types.isArbitraryPrecision(C)) {
            @compileError("zml.linalg.blas.dotu_sub not implemented for arbitrary precision types yet");
        } else {
            types.validateContext(@TypeOf(ctx), .{});
        }
    };

    if (comptime X == Y and options.link_cblas != null) {
        switch (comptime types.numericType(X)) {
            .cfloat => {
                if (comptime Scalar(X) == f32) {
                    return ci.cblas_cdotu_sub(scast(c_int, n), x, scast(c_int, incx), y, scast(c_int, incy), ret);
                } else if (comptime Scalar(X) == f64) {
                    return ci.cblas_zdotu_sub(scast(c_int, n), x, scast(c_int, incx), y, scast(c_int, incy), ret);
                }
            },
            else => {},
        }
    }

    return _dotu_sub(n, x, incx, y, incy, ret, ctx);
}

fn _dotu_sub(
    n: i32,
    x: anytype,
    incx: i32,
    y: anytype,
    incy: i32,
    ret: anytype,
    ctx: anytype,
) !void {
    const X: type = types.Child(@TypeOf(x));
    const Y: type = types.Child(@TypeOf(y));
    const C: type = types.Coerce(X, Y);
    const R: type = types.Child(@TypeOf(ret));

    try ops.set(ret, 0, ctx);

    if (n <= 0) return blas.Error.InvalidArgument;

    var ix: i32 = if (incx < 0) (-n + 1) * incx else 0;
    var iy: i32 = if (incy < 0) (-n + 1) * incy else 0;
    if (comptime types.isArbitraryPrecision(R)) {
        if (comptime types.isArbitraryPrecision(C)) {
            // Orientative implementation for arbitrary precision types
            var temp: C = try ops.init(C, ctx);
            defer ops.deinit(temp, ctx);
            for (0..scast(u32, n)) |_| {
                try ops.mul_(
                    &temp,
                    x[scast(u32, ix)],
                    y[scast(u32, iy)],
                    ctx,
                );

                try ops.add_(
                    ret,
                    ret.*,
                    temp,
                    ctx,
                );

                ix += incx;
                iy += incy;
            }

            @compileError("zml.linalg.blas.dotu_sub not implemented for arbitrary precision types yet");
        } else {
            @compileError("zml.linalg.blas.dotu_sub not implemented for arbitrary precision types yet");
        }
    } else {
        if (comptime types.isArbitraryPrecision(C)) {
            @compileError("zml.linalg.blas.dotu_sub not implemented for arbitrary precision types yet");
        } else {
            for (0..scast(u32, n)) |_| {
                ops.add_( // ret += x[ix] * y[iy]
                    ret,
                    ret.*,
                    ops.mul(
                        x[scast(u32, ix)],
                        y[scast(u32, iy)],
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
