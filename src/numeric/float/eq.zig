const float = @import("../float.zig");
const meta = @import("../meta.zig");
const numeric = @import("../numeric.zig");

/// Compares two operands of float, int or bool types, where at least one
/// operand must be of float type, for equality. The operation is performed by
/// casting both operands to the coerced type, then comparing them.
///
/// ## Signature
/// ```zig
/// float.eq(x: X, y: Y) bool
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
///
/// ## Returns
/// `bool`: `true` if the operands are equal, `false` otherwise.
pub fn eq(x: anytype, y: anytype) bool {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or
        !meta.numericType(X).le(.float) or !meta.numericType(Y).le(.float) or
        (meta.numericType(X) != .float and meta.numericType(Y) != .float))
        @compileError("zsl.float.eq: at least one of x or y must be a float, the other must be a bool, an int or a float, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    const C: type = float.Coerce(X, Y);

    return numeric.cast(C, x) == numeric.cast(C, y);
}
