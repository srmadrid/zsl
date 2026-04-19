const std = @import("std");

const types = @import("../../types.zig");
const scast = types.scast;
const Scalar = types.Scalar;
const Child = types.Child;
const EnsureFloat = types.EnsureFloat;
const float = @import("../../float.zig");
const ops = @import("../../ops.zig");
const constants = @import("../../constants.zig");

const blas = @import("../blas.zig");

/// Computes the Euclidean norm of a vector.
///
/// The `nrm2` routine performs a vector reduction operation defined as:
///
/// ```zig
///     ||x||,
/// ```
///
/// where `x` is a vector.
///
/// Signature
/// ---------
/// ```zig
/// fn nrm2(n: i32, x: [*]const X, incx: i32, ctx: anytype) !EnsureFloat(Scalar(X))
/// ```
///
/// Parameters
/// ----------
/// `n` (`i32`): Specifies the number of elements in vector `x`. Must be
/// greater than 0.
///
/// `x` (many-item pointer to, `int`, `float`, `cfloat`, `integer`, `rational`,
/// `real`, `complex` or `expression`): Array, size at least
/// `1 + (n - 1) * abs(incx)`.
///
/// `incx` (`i32`): Specifies the increment for indexing vector `x`. Must be
/// greater than 0.
///
/// Returns
/// -------
/// `EnsureFloat(Scalar(Child(@TypeOf(x))))`: The Euclidean norm of the vector.
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
pub fn nrm2(
    n: i32,
    x: anytype,
    incx: i32,
    ctx: anytype,
) !EnsureFloat(Scalar(Child(@TypeOf(x)))) {
    comptime var X: type = @TypeOf(x);

    comptime if (!types.isManyPointer(X))
        @compileError("zml.linalg.blas.nrm2 requires x to be a many-item pointer, got " ++ @typeName(X));

    X = types.Child(X);

    comptime if (!types.isNumeric(X))
        @compileError("zml.linalg.blas.nrm2 requires x's child type to be numeric, got " ++ @typeName(X));

    comptime if (X == bool)
        @compileError("zml.linalg.blas.nrm2 does not support x being bool");

    comptime if (types.isArbitraryPrecision(X)) {
        @compileError("zml.linalg.blas.nrm2 not implemented for arbitrary precision types yet");
    } else {
        types.validateContext(@TypeOf(ctx), .{});
    };

    if (comptime options.link_cblas != null) {
        switch (comptime types.numericType(X)) {
            .float => {
                if (comptime X == f32) {
                    return ci.cblas_snrm2(scast(c_int, n), x, scast(c_int, incx));
                } else if (comptime X == f64) {
                    return ci.cblas_dnrm2(scast(c_int, n), x, scast(c_int, incx));
                }
            },
            .cfloat => {
                if (comptime Scalar(X) == f32) {
                    return ci.cblas_scnrm2(scast(c_int, n), x, scast(c_int, incx));
                } else if (comptime Scalar(X) == f64) {
                    return ci.cblas_dznrm2(scast(c_int, n), x, scast(c_int, incx));
                }
            },
            else => {},
        }
    }

    return _nrm2(n, x, incx, ctx);
}

fn _nrm2(
    n: i32,
    x: anytype,
    incx: i32,
    ctx: anytype,
) !EnsureFloat(Scalar(Child(@TypeOf(x)))) {
    const X: type = Child(@TypeOf(x));

    if (n < 0) return blas.Error.InvalidArgument;

    if (n == 0)
        return try constants.zero(EnsureFloat(Scalar(X)), ctx);

    if (comptime types.isArbitraryPrecision(X)) {
        // Orientative implementation for arbitrary precision types
        var sum: EnsureFloat(Scalar(X)) = try ops.init(EnsureFloat(Scalar(X)), ctx);
        errdefer ops.deinit(&sum, ctx);
        var temp: EnsureFloat(Scalar(X)) = try ops.init(EnsureFloat(Scalar(X)), ctx);
        defer ops.deinit(&temp, ctx);

        var ix: i32 = if (incx < 0) (-n + 1) * incx else 0;
        for (0..scast(u32, n)) |_| {
            if (comptime types.isComplex(X)) {
                try ops.abs2_(&temp, x[scast(u32, ix)], ctx);
            } else {
                try ops.pow_(&temp, x[scast(u32, ix)], 2, ctx);
            }

            try ops.add_(&sum, sum, temp, ctx);

            ix += incx;
        }

        try ops.sqrt_(&sum, sum, ctx);
        //return sum;

        @compileError("zml.linalg.blas.nrm2 not implemented for arbitrary precision types yet");
    } else {
        const huge: EnsureFloat(Scalar(X)) = std.math.floatMax(EnsureFloat(Scalar(X)));
        const tsml: EnsureFloat(Scalar(X)) = float.pow(2, float.ceil((std.math.floatExponentMin(EnsureFloat(Scalar(X))) - 1) * @as(EnsureFloat(Scalar(X)), 0.5)));
        const tbig: EnsureFloat(Scalar(X)) = float.pow(2, float.floor((std.math.floatExponentMax(EnsureFloat(Scalar(X))) - @bitSizeOf(EnsureFloat(Scalar(X))) + 1) * @as(EnsureFloat(Scalar(X)), 0.5)));
        const ssml: EnsureFloat(Scalar(X)) = float.pow(2, -float.floor((std.math.floatExponentMin(EnsureFloat(Scalar(X))) - @bitSizeOf(EnsureFloat(Scalar(X)))) * @as(EnsureFloat(Scalar(X)), 0.5)));
        const sbig: EnsureFloat(Scalar(X)) = float.pow(2, -float.ceil((std.math.floatExponentMax(EnsureFloat(Scalar(X))) + @bitSizeOf(EnsureFloat(Scalar(X))) - 1) * @as(EnsureFloat(Scalar(X)), 0.5)));

        var scl: EnsureFloat(Scalar(X)) = 1;
        var sumsq: EnsureFloat(Scalar(X)) = 0;

        var abig: EnsureFloat(Scalar(X)) = 0;
        var amed: EnsureFloat(Scalar(X)) = 0;
        var asml: EnsureFloat(Scalar(X)) = 0;

        var notbig: bool = true;

        if (comptime types.numericType(X) == .cfloat) {
            var ix: i32 = if (incx < 0) (-n + 1) * incx else 0;
            for (0..scast(u32, n)) |_| {
                var ax: EnsureFloat(Scalar(X)) = float.abs(x[scast(u32, ix)].re);
                if (ax > tbig) {
                    abig += (ax * sbig) * (ax * sbig);
                    notbig = false;
                } else if (ax < tsml) {
                    if (notbig) asml += (ax * ssml) * (ax * ssml);
                } else {
                    amed += ax * ax;
                }

                ax = float.abs(x[scast(u32, ix)].im);
                if (ax > tbig) {
                    abig += (ax * sbig) * (ax * sbig);
                    notbig = false;
                } else if (ax < tsml) {
                    if (notbig) asml += (ax * ssml) * (ax * ssml);
                } else {
                    amed += ax * ax;
                }

                ix += incx;
            }
        } else {
            var ix: i32 = if (incx < 0) (-n + 1) * incx else 0;
            for (0..scast(u32, n)) |_| {
                const ax: EnsureFloat(Scalar(X)) = float.abs(x[scast(u32, ix)]);
                if (ax > tbig) {
                    abig += (ax * sbig) * (ax * sbig);
                    notbig = false;
                } else if (ax < tsml) {
                    if (notbig) asml += (ax * ssml) * (ax * ssml);
                } else {
                    amed += ax * ax;
                }

                ix += incx;
            }
        }

        if (abig > 0) {
            if (amed > 0 or amed > huge or amed != amed) {
                abig += (amed * sbig) * (amed * sbig);
            }
            scl = 1 / sbig;
            sumsq = abig;
        } else if (asml > 0) {
            if (amed > 0 or amed > huge or amed != amed) {
                const sqrt_amed = float.sqrt(amed);
                const sqrt_asml = float.sqrt(asml) / ssml;
                const ymin = if (sqrt_asml > sqrt_amed) sqrt_amed else sqrt_asml;
                const ymax = if (sqrt_asml > sqrt_amed) sqrt_asml else sqrt_amed;
                scl = 1;
                sumsq = (ymax * ymax) * (1 + (ymin / ymax) * (ymin / ymax));
            } else {
                scl = 1 / ssml;
                sumsq = asml;
            }
        } else {
            scl = 1;
            sumsq = amed;
        }

        return scl * float.sqrt(sumsq);
    }
}
