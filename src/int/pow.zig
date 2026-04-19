const meta = @import("../meta.zig");
const numeric = @import("../numeric.zig");

const int = @import("../int.zig");

pub fn Pow(comptime X: type, comptime Y: type) type {
    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or
        !meta.numericType(X).le(.int) or !meta.numericType(Y).le(.int) or
        (meta.numericType(X) != .int and meta.numericType(Y) != .int))
        @compileError("zsl.int.pow: at least one of x or y must be an int, the other must be a bool or an int, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    return int.Coerce(X, Y);
}

/// Performs exponentiation $x^y$ between two operands of int or bool types,
/// where at least one operand must be of int type. The result type is
/// determined by coercing the operand types, and the operation is performed by
/// casting both operands to the result type, then using exponentiation by
/// squaring for efficient computation.
///
/// ## Signature
/// ```zig
/// int.pow(x: X, y: Y) int.Pow(X, Y)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The base value.
/// * `y` (`anytype`): The exponent value.
///
/// ## Returns
/// `int.Pow(@TypeOf(x), @TypeOf(y))`: The result of raising `x` to the power of
/// `y`.
///
/// ## Errors
/// * `error.NegativeExponent`: If `y` is negative.
pub fn pow(x: anytype, y: anytype) int.Pow(@TypeOf(x), @TypeOf(y)) {
    const R: type = int.Pow(@TypeOf(x), @TypeOf(y));

    if (comptime R == comptime_int) {
        comptime var result: R = 1;
        comptime var base: R = numeric.cast(R, x);
        comptime var exponent: R = numeric.cast(R, y);

        if (exponent < 0)
            return 0;

        while (exponent != 0) : (exponent >>= 1) {
            if ((exponent & 1) != 0)
                result *= base;

            base *= base;
        }

        return result;
    } else {
        var result: R = 1;
        var base: R = numeric.cast(R, x);
        var exponent: R = numeric.cast(R, y);

        if (exponent < 0)
            return 0;

        while (exponent != 0) : (exponent >>= 1) {
            if ((exponent & 1) != 0)
                result = int.mul(result, base);

            base = int.mul(base, base);
        }

        return result;
    }
}
