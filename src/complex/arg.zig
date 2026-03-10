const types = @import("../types.zig");
const numeric = @import("../numeric.zig");

const complex = @import("../complex.zig");

pub fn Arg(comptime Z: type) type {
    comptime if (!types.isNumeric(Z) or types.numericType(Z) != .complex)
        @compileError("zsl.complex.arg: z must be a complex, got \n\tz: " ++ @typeName(Z) ++ "\n");

    return types.Scalar(Z);
}

/// Returns the argument of a complex `z`.
///
/// ## Signature
/// ```zig
/// complex.arg(z: Z) complex.Arg(Z)
/// ```
///
/// ## Arguments
/// * `z` (`anytype`): The complex value to get the argument of.
///
/// ## Returns
/// `complex.Arg(@TypeOf(z))`: The argument of `z`.
pub fn arg(z: anytype) complex.Arg(@TypeOf(z)) {
    return numeric.atan2(z.im, z.re);
}
