const int = @import("../int.zig");
const meta = @import("../meta.zig");
const numeric = @import("../numeric.zig");

pub fn Max(comptime X: type, comptime Y: type) type {
    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or
        !meta.numericType(X).le(.int) or !meta.numericType(Y).le(.int) or
        (meta.numericType(X) != .int and meta.numericType(Y) != .int))
        @compileError("zsl.int.Max: at least one of X or Y must be an int type, the other must be a bool or an int type, got\n\tX = " ++
            @typeName(X) ++ "\n\tY = " ++ @typeName(Y));

    return int.Coerce(X, Y);
}

/// Returns the maximum of two operands of int or bool types, where at least
/// one operand must be of int type. The result type is determined by coercing
/// the operand types, and the operation is performed by casting both operands
/// to the result type, then comparing them.
///
/// ## Signature
/// ```zig
/// int.max(x: X, y: Y) int.Max(X, Y)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
///
/// ## Returns
/// `int.Max(@TypeOf(x), @TypeOf(y))`: The maximum of the two operands.
pub fn max(x: anytype, y: anytype) int.Max(@TypeOf(x), @TypeOf(y)) {
    const R: type = int.Max(@TypeOf(x), @TypeOf(y));

    return if (numeric.cast(R, x) > numeric.cast(R, y)) numeric.cast(R, x) else numeric.cast(R, y);
}
