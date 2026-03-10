const types = @import("../types.zig");
const numeric = @import("../numeric.zig");

const complex = @import("../complex.zig");

/// Returns the hyperbolic sine `sinh(z)` of a complex.
///
/// ## Signature
/// ```zig
/// complex.sinh(z: Z) Z
/// ```
///
/// ## Arguments
/// * `z` (`anytype`): The value to get the hyperbolic sine of.
///
/// ## Returns
/// `@TypeOf(z)`: The hyperbolic sine of `z`.
pub fn sinh(z: anytype) @TypeOf(z) {
    const Z = @TypeOf(z);

    comptime if (!types.isNumeric(Z) or types.numericType(Z) != .complex)
        @compileError("zsl.complex.sinh: z must be a complex, got \n\tz: " ++ @typeName(Z) ++ "\n");

    return .{
        .re = numeric.mul(numeric.sinh(z.re), numeric.cos(z.im)),
        .im = numeric.mul(numeric.cosh(z.re), numeric.sin(z.im)),
    };
}
