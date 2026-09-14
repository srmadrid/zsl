const options = @import("options");

const int = @import("../int.zig");
const meta = @import("../meta.zig");
const numeric = @import("../numeric.zig");

pub fn Mul(comptime X: type, comptime Y: type) type {
    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or
        !meta.numericType(X).le(.int) or !meta.numericType(Y).le(.int) or
        (meta.numericType(X) != .int and meta.numericType(Y) != .int))
        @compileError("zsl.int.Mul: at least one of X or Y must be an int type, the other must be a bool or an int type, got\n\tX = " ++
            @typeName(X) ++ "\n\tY = " ++ @typeName(Y));

    return int.Coerce(X, Y);
}

/// Performs multiplication between two operands of int or bool types, where at
/// least one operand must be of int type. The result type is determined by
/// coercing the operand types, and the operation is performed by casting both
/// operands to the result type, then multiplying them.
///
/// Depending on the global int operation mode set in `options.int_mode`,
/// the multiplication will behave differently in case of over/underflow:
/// * `.default`: Standard multiplication, which will panic on over/underflow.
/// * `.wrap`: Multiplication with wrapping behavior on over/underflow.
/// * `.saturate`: Multiplication with saturation behavior on over/underflow.
///
/// ## Signature
/// ```zig
/// int.mul(x: X, y: Y) int.Mul(X, Y)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
///
/// ## Returns
/// `int.Mul(@TypeOf(x), @TypeOf(y))`: The result of the multiplication.
pub fn mul(x: anytype, y: anytype) int.Mul(@TypeOf(x), @TypeOf(y)) {
    const R: type = int.Mul(@TypeOf(x), @TypeOf(y));

    switch (comptime options.int_mode) {
        .default => return numeric.cast(R, x) * numeric.cast(R, y),
        .wrap => return numeric.cast(R, x) *% numeric.cast(R, y),
        .saturate => return numeric.cast(R, x) *| numeric.cast(R, y),
    }
}
