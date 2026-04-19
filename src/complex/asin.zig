const meta = @import("../meta.zig");
const numeric = @import("../numeric.zig");

const complex = @import("../complex.zig");

/// Returns the arcsine `sin⁻¹(z)` of a complex.
///
/// ## Signature
/// ```zig
/// complex.asin(z: Z) Z
/// ```
///
/// ## Arguments
/// * `z` (`anytype`): The value to get the arcsine of.
///
/// ## Returns
/// `@TypeOf(z)`: The arcsine of `z`.
pub fn asin(z: anytype) @TypeOf(z) {
    const Z = @TypeOf(z);

    comptime if (!meta.isNumeric(Z) or meta.numericType(Z) != .complex)
        @compileError("zsl.complex.asin: z must be a complex, got \n\tz: " ++ @typeName(Z) ++ "\n");

    const r1 = numeric.abs(numeric.add(z, numeric.one(Z)));
    const r2 = numeric.abs(numeric.sub(z, numeric.one(Z)));

    const sum = numeric.add(r1, r2);
    const diff = numeric.sub(r1, r2);

    const u = numeric.div(diff, numeric.two(@TypeOf(diff)));
    const v = numeric.div(sum, numeric.two(@TypeOf(sum)));

    const re = numeric.asin(u);
    const im = numeric.acosh(v);

    return .{
        .re = re,
        .im = if (numeric.lt(z.im, numeric.one(@TypeOf(z.im)))) numeric.neg(im) else im,
    };
}
