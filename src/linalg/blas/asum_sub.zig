const std = @import("std");

const types = @import("../../types.zig");
const scast = types.scast;
const Scalar = types.Scalar;
const ops = @import("../../ops.zig");

const blas = @import("../blas.zig");

/// Computes the sum of magnitudes of the vector elements.
///
/// The `asum_sub` routine computes the sum of the magnitudes of elements of a
/// real vector, or the sum of magnitudes of the real and imaginary parts of
/// elements of a complex vector:
///
/// ```zig
///     ret = abs(x[0].re) + abs(x[0].im) + abs(x[1].re) + abs(x[1].im) + ... + abs(x[n - 1].re) + abs(x[n - 1].im),
/// ```
///
/// where `x` is a vector with `n` elements.
///
/// Signature
/// ---------
/// ```zig
/// fn asum_sub(n: i32, x: [*]const X, incx: i32, ret: *R, ctx: anytype) !void
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
/// `linalg.blas.Error.InvalidArgument`: If `n` or `incx` is less than or equal
/// to 0.
///
/// Notes
/// -----
/// If the `link_cblas` option is not `null`, the function will try to call the
/// corresponding CBLAS function, if available. In that case, no errors will be
/// raised even if the arguments are invalid.
pub fn asum_sub(
    n: i32,
    x: anytype,
    incx: i32,
    ret: anytype,
    ctx: anytype,
) !void {
    comptime var X: type = @TypeOf(x);
    comptime var R: type = @TypeOf(ret);

    comptime if (!types.isManyPointer(X))
        @compileError("zml.linalg.blas.asum_sub requires x to be a many-item pointer, got " ++ @typeName(X));

    X = types.Child(X);

    comptime if (!types.isNumeric(X) or X == bool)
        @compileError("zml.linalg.blas.asum_sub requires x's child type to be a non bool numeric, got " ++ @typeName(X));

    comptime if (!types.isPointer(R) or types.isConstPointer(R))
        @compileError("zml.linalg.blas.asum_sub requires ret to be a mutable one-item pointer, got " ++ @typeName(R));

    R = types.Child(R);

    comptime if (!types.isNumeric(R))
        @compileError("zml.linalg.blas.asum_sub requires ret's child type to be numeric, got " ++ @typeName(R));

    comptime if (types.isArbitraryPrecision(R)) {
        if (types.isArbitraryPrecision(X)) {
            @compileError("zml.linalg.blas.asum_sub not implemented for arbitrary precision types yet");
        } else {
            @compileError("zml.linalg.blas.asum_sub not implemented for arbitrary precision types yet");
        }
    } else {
        if (types.isArbitraryPrecision(X)) {
            @compileError("zml.linalg.blas.asum_sub not implemented for arbitrary precision types yet");
        } else {
            types.validateContext(@TypeOf(ctx), .{});
        }
    };

    if (comptime options.link_cblas != null) {
        switch (comptime types.numericType(X)) {
            .float => {
                if (comptime X == f32) {
                    try ops.set(ret, ci.cblas_sasum(scast(c_int, n), x, scast(c_int, incx)), ctx);
                } else if (comptime X == f64) {
                    try ops.set(ret, ci.cblas_dasum(scast(c_int, n), x, scast(c_int, incx)), ctx);
                }
            },
            .cfloat => {
                if (comptime Scalar(X) == f32) {
                    try ops.set(ret, ci.cblas_scasum(scast(c_int, n), x, scast(c_int, incx)), ctx);
                } else if (comptime Scalar(X) == f64) {
                    try ops.set(ret, ci.cblas_dzasum(scast(c_int, n), x, scast(c_int, incx)), ctx);
                }
            },
            else => {},
        }
    }

    return _asum_sub(X, n, x, incx, ret, ctx);
}

fn _asum_sub(
    n: i32,
    x: anytype,
    incx: i32,
    ret: anytype,
    ctx: anytype,
) !void {
    const X: type = types.Child(@TypeOf(x));
    const R: type = types.Child(@TypeOf(ret));

    try ops.set(ret, 0, ctx);

    if (n <= 0 or incx <= 0)
        return blas.Error.InvalidArgument;

    var ix: i32 = 0;
    if (comptime types.isArbitraryPrecision(R)) {
        if (comptime types.isArbitraryPrecision(X)) {
            // Orientative implementation for arbitrary precision types
            if (comptime types.isComplex(X)) {
                var temp: Scalar(X) = try ops.init(Scalar(X), ctx);
                defer ops.deinit(&temp, ctx);
                for (0..scast(u32, n)) |_| {
                    try ops.add_(
                        &temp,
                        ops.abs(x[scast(u32, ix)].re, types.mixStructs(ctx, .{ .copy = false })) catch unreachable,
                        ops.abs(x[scast(u32, ix)].im, types.mixStructs(ctx, .{ .copy = false })) catch unreachable,
                        ctx,
                    );

                    try ops.add_(ret, ret.*, temp, ctx);

                    ix += incx;
                }
            } else {
                for (0..scast(u32, n)) |_| {
                    try ops.add_(
                        ret,
                        ret.*,
                        ops.abs(x[scast(u32, ix)], types.mixStructs(ctx, .{ .copy = false })) catch unreachable,
                        ctx,
                    );

                    ix += incx;
                }
            }

            @compileError("zml.linalg.blas.asum_sub not implemented for arbitrary precision types yet");
        } else {
            @compileError("zml.linalg.blas.asum_sub not implemented for arbitrary precision types yet");
        }
    } else {
        if (comptime types.isArbitraryPrecision(X)) {
            @compileError("zml.linalg.blas.asum_sub not implemented for arbitrary precision types yet");
        } else {
            if (comptime types.isComplex(X)) {
                for (0..scast(u32, n)) |_| {
                    ops.add_( // ret += |x[ix].re| + |x[ix].im|
                        ret,
                        ret.*,
                        ops.add(
                            ops.abs(x[scast(u32, ix)].re, ctx) catch unreachable,
                            ops.abs(x[scast(u32, ix)].im, ctx) catch unreachable,
                            ctx,
                        ) catch unreachable,
                        ctx,
                    ) catch unreachable;

                    ix += incx;
                }
            } else {
                for (0..scast(u32, n)) |_| {
                    ops.add_( // ret += |x[ix]|
                        ret,
                        ret.*,
                        ops.abs(x[scast(u32, ix)], ctx) catch unreachable,
                        ctx,
                    ) catch unreachable;

                    ix += incx;
                }
            }
        }
    }
}
