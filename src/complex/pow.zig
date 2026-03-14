const types = @import("../types.zig");
const numeric = @import("../numeric.zig");

const complex = @import("../complex.zig");

pub fn Pow(comptime X: type, comptime Y: type) type {
    comptime if (!types.isNumeric(X) or !types.isNumeric(Y) or
        !types.numericType(X).le(.complex) or !types.numericType(Y).le(.complex) or
        (types.numericType(X) != .complex and types.numericType(Y) != .complex))
        @compileError("zsl.complex.pow: at least one of x or y must be a complex, the other must be a bool, an int, a float, a dyadic or a complex, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    return complex.Coerce(X, Y);
}

/// Performs exponentiation `xʸ` between two operands of complex, dyadic, float,
/// int or bool types, where at least one operand must be of float type. The
/// result type is determined by coercing the operand types, and the operation
/// is performed by casting both operands to the result type, then performing
/// the exponentiation.
///
/// ## Signature
/// ```zig
/// complex.pow(x: X, y: Y) complex.Pow(X, Y)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The base value.
/// * `y` (`anytype`): The exponent value.
///
/// ## Returns
/// `complex.Pow(@TypeOf(x), @TypeOf(y))`: The result of raising `x` to the power
/// of `y`.
pub fn pow(x: anytype, y: anytype) complex.Pow(@TypeOf(x), @TypeOf(y)) {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);
    // const R: type = complex.Pow(X, Y);

    if (comptime !types.isComplex(X)) {
        // x is real, y is complex
        const r = numeric.pow(x, y.re);
        const theta = numeric.mul(y.im, numeric.ln(x));

        return .{
            .re = numeric.mul(r, numeric.cos(theta)),
            .im = numeric.mul(r, numeric.sin(theta)),
        };
    } else if (comptime !types.isComplex(Y)) {
        // x is complex, y is real
        const r = numeric.pow(complex.abs(x), y);
        const theta = numeric.mul(complex.arg(x), y);

        return .{
            .re = numeric.mul(r, numeric.cos(theta)),
            .im = numeric.mul(r, numeric.sin(theta)),
        };
    } else {
        // x and y both complex
        const r = complex.abs(x);
        const theta = complex.arg(x);
        const ln_r = numeric.ln(r);

        const a = numeric.exp(numeric.fma(y.re, ln_r, numeric.neg(numeric.mul(y.im, theta))));
        const b = numeric.fma(y.re, theta, numeric.mul(y.im, ln_r));

        return .{
            .re = numeric.mul(a, numeric.cos(b)),
            .im = numeric.mul(a, numeric.sin(b)),
        };
    }
}
