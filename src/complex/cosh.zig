const meta = @import("../meta.zig");
const numeric = @import("../numeric.zig");

const complex = @import("../complex.zig");

/// Returns the hyperbolic cosine `cosh(z)` of a complex.
///
/// ## Signature
/// ```zig
/// complex.cosh(z: Z) Z
/// ```
///
/// ## Arguments
/// * `z` (`anytype`): The value to get the hyperbolic cosine of.
///
/// ## Returns
/// `@TypeOf(z)`: The hyperbolic cosine of `z`.
pub fn cosh(z: anytype) @TypeOf(z) {
    const Z = @TypeOf(z);

    comptime if (!meta.isNumeric(Z) or meta.numericType(Z) != .complex)
        @compileError("zsl.complex.cosh: z must be a complex, got \n\tz: " ++ @typeName(Z) ++ "\n");

    return .{
        .re = numeric.mul(numeric.cosh(z.re), numeric.cos(z.im)),
        .im = numeric.mul(numeric.sinh(z.re), numeric.sin(z.im)),
    };
}
