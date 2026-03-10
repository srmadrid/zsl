const types = @import("../types.zig");
const numeric = @import("../numeric.zig");

const complex = @import("../complex.zig");

pub fn Abs2(comptime Z: type) type {
    comptime if (!types.isNumeric(Z) or types.numericType(Z) != .complex)
        @compileError("zsl.complex.abs2: z must be a complex, got \n\tz: " ++ @typeName(Z) ++ "\n");

    return types.Scalar(Z);
}

/// Returns the squared absolute value of a complex `z`.
///
/// ## Signature
/// ```zig
/// complex.abs2(z: Z) complex.Abs2(Z)
/// ```
///
/// ## Arguments
/// * `z` (`anytype`): The complex value to get the squared absolute value of.
///
/// ## Returns
/// `complex.Abs2(@TypeOf(z))`: The squared absolute value of `z`.
pub fn abs2(z: anytype) complex.Abs2(@TypeOf(z)) {
    return numeric.add(numeric.mul(z.re, z.re), numeric.mul(z.im, z.im));
}
