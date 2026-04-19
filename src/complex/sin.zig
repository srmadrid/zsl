const meta = @import("../meta.zig");
const numeric = @import("../numeric.zig");

const complex = @import("../complex.zig");

/// Returns the sine `sin(z)` of a complex.
///
/// ## Signature
/// ```zig
/// complex.sin(z: Z) Z
/// ```
///
/// ## Arguments
/// * `z` (`anytype`): The value to get the sine of.
///
/// ## Returns
/// `@TypeOf(z)`: The sine of `z`.
pub fn sin(z: anytype) @TypeOf(z) {
    const Z = @TypeOf(z);

    comptime if (!meta.isNumeric(Z) or meta.numericType(Z) != .complex)
        @compileError("zsl.complex.sin: z must be a complex, got \n\tz: " ++ @typeName(Z) ++ "\n");

    return .{
        .re = numeric.mul(numeric.sin(z.re), numeric.cosh(z.im)),
        .im = numeric.mul(numeric.cos(z.re), numeric.sinh(z.im)),
    };
}
