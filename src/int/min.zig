const int = @import("../int.zig");
const meta = @import("../meta.zig");
const numeric = @import("../numeric.zig");

pub fn Min(comptime X: type, comptime Y: type) type {
    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or
        !meta.numericType(X).le(.int) or !meta.numericType(Y).le(.int) or
        (meta.numericType(X) != .int and meta.numericType(Y) != .int))
        @compileError("zsl.int.Min: at least one of X or Y must be an int type, the other must be a bool or an int type, got\n\tX = " ++
            @typeName(X) ++ "\n\tY = " ++ @typeName(Y));

    return int.Coerce(X, Y);
}

/// Returns the minimum of two operands of int or bool types, where at least
/// one operand must be of int type. The result type is determined by coercing
/// the operand types, and the operation is performed by casting both operands
/// to the result type, then comparing them.
///
/// ## Signature
/// ```zig
/// int.min(x: X, y: Y) int.Min(X, Y)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
///
/// ## Returns
/// `int.Min(@TypeOf(x), @TypeOf(y))`: The minimum of the two operands.
pub fn min(x: anytype, y: anytype) int.Min(@TypeOf(x), @TypeOf(y)) {
    const R: type = int.Min(@TypeOf(x), @TypeOf(y));

    return if (numeric.cast(R, x) < numeric.cast(R, y)) numeric.cast(R, x) else numeric.cast(R, y);
}
