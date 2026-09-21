const meta = @import("../meta.zig");
const numeric = @import("../numeric.zig");

const complex = @import("../complex.zig");

/// Returns the exponential `eᶻ` of a complex.
///
/// ## Signature
/// ```zig
/// complex.exp(z: Z) Z
/// ```
///
/// ## Arguments
/// * `z` (`anytype`): The value to get the exponential of.
///
/// ## Returns
/// `@TypeOf(z)`: The exponential of `z`.
pub fn exp(z: anytype) @TypeOf(z) {
    const Z = @TypeOf(z);

    comptime if (!meta.isNumeric(Z) or meta.numericType(Z) != .complex)
        @compileError("zsl.complex.exp: z must be a complex, got \n\tz: " ++ @typeName(Z) ++ "\n");

    const r = numeric.exp(z.re);
    return .{
        .re = numeric.mul(r, numeric.cos(z.im)),
        .im = numeric.mul(r, numeric.sin(z.im)),
    };
}
