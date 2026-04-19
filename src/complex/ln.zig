const meta = @import("../meta.zig");
const numeric = @import("../numeric.zig");

const complex = @import("../complex.zig");

/// Returns the natural logarithm `logₑ(z)` of a complex.
///
/// ## Signature
/// ```zig
/// complex.ln(z: Z) Z
/// ```
///
/// ## Arguments
/// * `z` (`anytype`): The value to get the natural logarithm of.
///
/// ## Returns
/// `@TypeOf(z)`: The natural logarithm of `z`.
pub fn ln(z: anytype) @TypeOf(z) {
    const Z = @TypeOf(z);

    comptime if (!meta.isNumeric(Z) or meta.numericType(Z) != .complex)
        @compileError("zsl.complex.ln: z must be a complex, got \n\tz: " ++ @typeName(Z) ++ "\n");

    return .{
        .re = numeric.ln(complex.abs(z)),
        .im = complex.arg(z),
    };
}
