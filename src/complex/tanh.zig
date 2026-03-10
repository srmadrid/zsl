const types = @import("../types.zig");
const numeric = @import("../numeric.zig");

const complex = @import("../complex.zig");

/// Returns the hyperbolic tangent `tanh(z)` of a complex.
///
/// ## Signature
/// ```zig
/// complex.tanh(z: Z) Z
/// ```
///
/// ## Arguments
/// * `z` (`anytype`): The value to get the hyperbolic tangent of.
///
/// ## Returns
/// `@TypeOf(z)`: The hyperbolic tangent of `z`.
pub fn tanh(z: anytype) @TypeOf(z) {
    const Z = @TypeOf(z);

    comptime if (!types.isNumeric(Z) or types.numericType(Z) != .complex)
        @compileError("zsl.complex.tanh: z must be a complex, got \n\tz: " ++ @typeName(Z) ++ "\n");

    if (numeric.ge(z.re, numeric.zero(@TypeOf(z.re)))) {
        const w = numeric.exp(numeric.mul(z, numeric.neg(numeric.two(@TypeOf(z)))));

        return numeric.div(
            numeric.sub(numeric.one(@TypeOf(w)), w),
            numeric.add(numeric.one(@TypeOf(w)), w),
        );
    } else {
        const w = numeric.exp(numeric.mul(z, numeric.two(@TypeOf(z))));

        return numeric.div(
            numeric.sub(w, numeric.one(@TypeOf(w))),
            numeric.add(w, numeric.one(@TypeOf(w))),
        );
    }
}
