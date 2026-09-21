const meta = @import("../meta.zig");
const numeric = @import("../numeric.zig");

const complex = @import("../complex.zig");

/// Returns the arctangent `tan⁻¹(z)` of a complex.
///
/// ## Signature
/// ```zig
/// complex.atan(z: Z) Z
/// ```
///
/// ## Arguments
/// * `z` (`anytype`): The value to get the arctangent of.
///
/// ## Returns
/// `@TypeOf(z)`: The arctangent of `z`.
pub fn atan(z: anytype) @TypeOf(z) {
    const Z = @TypeOf(z);

    comptime if (!meta.isNumeric(Z) or meta.numericType(Z) != .complex)
        @compileError("zsl.complex.atan: z must be a complex, got \n\tz: " ++ @typeName(Z) ++ "\n");

    const re_two = numeric.mul(z.re, z.re);
    const im_two = numeric.mul(z.im, z.im);

    const two_re = numeric.mul(2, z.re);
    const one_minus_r2 = numeric.sub(1, numeric.add(re_two, im_two));

    const num = numeric.fma(numeric.add(z.im, 1), numeric.add(z.im, 1), re_two);
    const den = numeric.fma(numeric.sub(z.im, 1), numeric.sub(z.im, 1), re_two);

    return .{
        .re = numeric.div(numeric.atan2(two_re, one_minus_r2), 2),
        .im = numeric.div(numeric.ln(numeric.div(num, den)), 4),
    };
}
