const meta = @import("../meta.zig");
const numeric = @import("../numeric.zig");

const complex = @import("../complex.zig");

/// Returns the cosine `cos(z)` of a complex.
///
/// ## Signature
/// ```zig
/// complex.cos(z: Z) Z
/// ```
///
/// ## Arguments
/// * `z` (`anytype`): The value to get the cosine of.
///
/// ## Returns
/// `@TypeOf(z)`: The cosine of `z`.
pub fn cos(z: anytype) @TypeOf(z) {
    const Z = @TypeOf(z);

    comptime if (!meta.isNumeric(Z) or meta.numericType(Z) != .complex)
        @compileError("zsl.complex.cos: z must be a complex, got \n\tz: " ++ @typeName(Z) ++ "\n");

    return .{
        .re = numeric.mul(numeric.cos(z.re), numeric.cosh(z.im)),
        .im = numeric.mul(numeric.sin(z.re), numeric.sinh(z.im)),
    };
}
