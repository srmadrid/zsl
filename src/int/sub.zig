const options = @import("options");

const int = @import("../int.zig");
const meta = @import("../meta.zig");
const numeric = @import("../numeric.zig");

pub fn Sub(comptime X: type, comptime Y: type) type {
    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or
        !meta.numericType(X).le(.int) or !meta.numericType(Y).le(.int) or
        (meta.numericType(X) != .int and meta.numericType(Y) != .int))
        @compileError("zsl.int.Sub: at least one of X or Y must be an int type, the other must be a bool or an int type, got\n\tX = " ++
            @typeName(X) ++ "\n\tY = " ++ @typeName(Y) ++ "\n");

    return int.Coerce(X, Y);
}

/// Performs subtraction between two operands of int or bool types, where at
/// least one operand must be of int type. The result type is determined by
/// coercing the operand types, and the operation is performed by casting both
/// operands to the result type, then subtracting them.
///
/// Depending on the global int operation mode set in `options.int_mode`,
/// the subtraction will behave differently in case of over/underflow:
/// * `.default`: Standard subtraction, which will panic on over/underflow.
/// * `.wrap`: Subtraction with wrapping behavior on over/underflow.
/// * `.saturate`: Subtraction with saturation behavior on over/underflow.
///
/// ## Signature
/// ```zig
/// int.sub(x: X, y: Y) int.Sub(X, Y)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
///
/// ## Returns
/// `int.Sub(@TypeOf(x), @TypeOf(y))`: The result of the subtraction.
pub fn sub(x: anytype, y: anytype) int.Sub(@TypeOf(x), @TypeOf(y)) {
    const R: type = int.Sub(@TypeOf(x), @TypeOf(y));

    switch (comptime options.int_mode) {
        .default => return numeric.cast(R, x) - numeric.cast(R, y),
        .wrap => return numeric.cast(R, x) -% numeric.cast(R, y),
        .saturate => return numeric.cast(R, x) -| numeric.cast(R, y),
    }
}
