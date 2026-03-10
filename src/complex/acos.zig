const types = @import("../types.zig");
const numeric = @import("../numeric.zig");

const complex = @import("../complex.zig");

/// Returns the arccosine `cos⁻¹(z)` of a complex.
///
/// ## Signature
/// ```zig
/// complex.acos(z: Z) Z
/// ```
///
/// ## Arguments
/// * `z` (`anytype`): The value to get the arccosine of.
///
/// ## Returns
/// `@TypeOf(z)`: The arccosine of `z`.
pub fn acos(z: anytype) @TypeOf(z) {
    const Z = @TypeOf(z);

    comptime if (!types.isNumeric(Z) or types.numericType(Z) != .complex)
        @compileError("zsl.complex.acos: z must be a complex, got \n\tz: " ++ @typeName(Z) ++ "\n");

    const prod = numeric.mul(
        numeric.sqrt(numeric.sub(numeric.one(Z), z)),
        numeric.sqrt(numeric.add(numeric.one(Z), z)),
    );

    const i_prod = @TypeOf(prod){
        .re = numeric.neg(prod.im),
        .im = prod.re,
    };

    const inner = numeric.ln(numeric.add(z, i_prod));

    return .{
        .re = inner.im,
        .im = numeric.neg(inner.re),
    };
}
