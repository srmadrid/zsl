const std = @import("std");

const types = @import("../../types.zig");
const scast = types.scast;
const Scalar = types.Scalar;
const ops = @import("../../ops.zig");
const blas = @import("../blas.zig");

/// Performs rotation of points in the plane.
///
/// Given two vectors `x` and `y`, each vector element of these vectors is r
/// eplaced as follows:
///
/// ```zig
///     x[i] = c * x[i] + s * y[i]
///     y[i] = c * y[i] - s * x[i]
/// ```
///
/// Signature
/// ---------
/// ```zig
/// fn rot(n: i32, x: [*]X, incx: i32, y: [*]Y, incy: i32, c: C, s: S, ctx: anytype) !void
/// ```
///
/// Parameters
/// ----------
/// `n` (`i32`): Specifies the number of elements in vectors `x` and `y`. Must
/// be greater than 0.
///
/// `x` (mutable many-item pointer to `bool`, `int`, `float`, `cfloat`,
/// `integer`, `rational`, `real`, `complex` or `expression`): Array, size at
/// least `1 + (n - 1) * abs(incx)`.
///
/// `incx` (`i32`): Specifies the increment for the elements of `x`.
///
/// `y` (mutable many-item pointer to `bool`, `int`, `float`, `cfloat`,
/// `integer`, `rational`, `real`, `complex` or `expression`): Array, size at
/// least `1 + (n - 1) * abs(incy)`.
///
/// `incy` (`i32`): Specifies the increment for the elements of `y`.
///
/// `c` (`bool`, `int`, `float`, `integer`, `rational`, `real` or `expression`):
/// The cosine of the rotation angle.
///
/// `s` (`bool`, `int`, `float`, `integer`, `rational`, `real` or `expression`):
/// The sine of the rotation angle.
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
pub fn rot(
    n: i32,
    x: anytype,
    incx: i32,
    y: anytype,
    incy: i32,
    c: anytype,
    s: anytype,
    ctx: anytype,
) !void {
    comptime var X: type = @TypeOf(x);
    comptime var Y: type = @TypeOf(y);
    const C: type = @TypeOf(c);
    const S: type = @TypeOf(s);

    comptime if (!types.isManyPointer(X) or types.isConstPointer(X))
        @compileError("zml.linalg.blas.rot requires x to be a mutable many-item pointer, got " ++ @typeName(X));

    X = types.Child(X);

    comptime if (!types.isNumeric(X))
        @compileError("zml.linalg.blas.rot requires x's child type to be numeric, got " ++ @typeName(X));

    comptime if (!types.isManyPointer(Y) or types.isConstPointer(Y))
        @compileError("zml.linalg.blas.rot requires y to be a mutable many-item pointer, got " ++ @typeName(Y));

    Y = types.Child(Y);

    comptime if (!types.isNumeric(Y))
        @compileError("zml.linalg.blas.rot requires y's child type to be numeric, got " ++ @typeName(Y));

    comptime if (!types.isNumeric(C))
        @compileError("zml.linalg.blas.rot requires c to be numeric, got " ++ @typeName(C));

    comptime if (types.isComplex(C))
        @compileError("zml.linalg.blas.rot does not support c being complex, got " ++ @typeName(C));

    comptime if (!types.isNumeric(S))
        @compileError("zml.linalg.blas.rot requires s to be numeric, got " ++ @typeName(S));

    comptime if (types.isComplex(S))
        @compileError("zml.linalg.blas.rot does not support s being complex, got " ++ @typeName(S));

    comptime if (X == bool and Y == bool and C == bool and S == bool)
        @compileError("zml.linalg.blas.rot does not support x, y, c and s all being bool");

    comptime if (types.isArbitraryPrecision(X) or
        types.isArbitraryPrecision(Y) or
        types.isArbitraryPrecision(C) or
        types.isArbitraryPrecision(S))
    {
        // When implemented, expand if
        @compileError("zml.linalg.blas.rot not implemented for arbitrary precision types yet");
    } else {
        types.validateContext(@TypeOf(ctx), .{});
    };

    if (comptime X == Y and X == C and X == S and options.link_cblas != null) {
        switch (comptime types.numericType(X)) {
            .float => {
                if (comptime X == f32) {
                    return ci.cblas_srot(scast(c_int, n), x, scast(c_int, incx), y, scast(c_int, incy), c, s);
                } else if (comptime X == f64) {
                    return ci.cblas_drot(scast(c_int, n), x, scast(c_int, incx), y, scast(c_int, incy), c, s);
                }
            },
            .cfloat => {
                if (comptime Scalar(X) == f32) {
                    return ci.cblas_csrot(scast(c_int, n), x, scast(c_int, incx), y, scast(c_int, incy), c, s);
                } else if (comptime Scalar(X) == f64) {
                    return ci.cblas_zdrot(scast(c_int, n), x, scast(c_int, incx), y, scast(c_int, incy), c, s);
                }
            },
            else => {},
        }
    }

    return _rot(n, x, incx, y, incy, c, s, ctx);
}

fn _rot(
    n: i32,
    x: anytype,
    incx: i32,
    y: anytype,
    incy: i32,
    c: anytype,
    s: anytype,
    ctx: anytype,
) !void {
    const X: type = types.Child(@TypeOf(x));
    const Y: type = types.Child(@TypeOf(y));
    const C: type = @TypeOf(c);
    const S: type = @TypeOf(s);
    const Ca: type = types.Coerce(X, types.Coerce(Y, types.Coerce(C, S)));

    if (n <= 0) return blas.Error.InvalidArgument;

    if (ops.eq(c, 1, .{}) catch unreachable and ops.eq(s, 0, .{}) catch unreachable) return;

    var ix: i32 = if (incx < 0) (-n + 1) * incx else 0;
    var iy: i32 = if (incy < 0) (-n + 1) * incy else 0;

    var temp: Ca = try ops.init(Ca, .{});
    for (0..scast(u32, n)) |_| {
        ops.add_( // temp = c * x[ix] + s * y[iy]
            &temp,
            ops.mul(
                c,
                x[scast(u32, ix)],
                ctx,
            ) catch unreachable,
            ops.mul(
                s,
                y[scast(u32, iy)],
                ctx,
            ) catch unreachable,
            ctx,
        ) catch unreachable;

        ops.sub_( // y[iy] = c * y[iy] - s * x[ix]
            &y[scast(u32, iy)],
            ops.mul(
                c,
                y[scast(u32, iy)],
                ctx,
            ) catch unreachable,
            ops.mul(
                s,
                x[scast(u32, ix)],
                ctx,
            ) catch unreachable,
            ctx,
        ) catch unreachable;

        ops.set( // x[ix] = temp
            &x[scast(u32, ix)],
            temp,
            ctx,
        ) catch unreachable;

        ix += incx;
        iy += incy;
    }
}
