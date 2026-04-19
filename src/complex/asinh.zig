const meta = @import("../meta.zig");
const numeric = @import("../numeric.zig");

const complex = @import("../complex.zig");

/// Returns the hyperbolic arcsine `sinh⁻¹(z)` of a complex.
///
/// ## Signature
/// ```zig
/// complex.asinh(z: Z) Z
/// ```
///
/// ## Arguments
/// * `z` (`anytype`): The value to get the hyperbolic arcsine of.
///
/// ## Returns
/// `@TypeOf(z)`: The hyperbolic arcsine of `z`.
pub fn asinh(z: anytype) @TypeOf(z) {
    const Z = @TypeOf(z);

    comptime if (!meta.isNumeric(Z) or meta.numericType(Z) != .complex)
        @compileError("zsl.complex.asinh: z must be a complex, got \n\tz: " ++ @typeName(Z) ++ "\n");

    const z_first_quad = Z{
        .re = numeric.abs(z.re),
        .im = numeric.abs(z.im),
    };

    const w = numeric.fma(z_first_quad, z_first_quad, numeric.one(Z));

    const root = numeric.sqrt(w);
    const sum = numeric.add(z_first_quad, root);
    const quad_result = numeric.ln(sum);

    return .{
        .re = if (numeric.lt(z.re, numeric.zero(@TypeOf(z.re)))) numeric.neg(quad_result.re) else quad_result.re,
        .im = if (numeric.lt(z.im, numeric.zero(@TypeOf(z.im)))) numeric.neg(quad_result.im) else quad_result.im,
    };
}
