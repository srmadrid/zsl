const std = @import("std");

const int = @import("../int.zig");
const meta = @import("../meta.zig");
const numeric = @import("../numeric.zig");

/// Compares two operands of int or bool types, where at least one operand must
/// be of int type, for ordering. The operation is performed by casting both
/// operands to the coerced type, then comparing them.
///
/// ## Signature
/// ```zig
/// int.order(x: X, y: Y) std.math.Order
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
///
/// ## Returns
/// `std.math.Order`: The result of the comparison.
pub fn order(x: anytype, y: anytype) std.math.Order {
    const X: type = @TypeOf(x);
    const Y: type = @TypeOf(y);

    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or
        !meta.numericType(X).le(.int) or !meta.numericType(Y).le(.int) or
        (meta.numericType(X) != .int and meta.numericType(Y) != .int))
        @compileError("zsl.int.order: at least one of x or y must be an int, the other must be a bool or an int, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y));

    const C: type = int.Coerce(X, Y);

    if (numeric.cast(C, x) < numeric.cast(C, y)) return .lt;
    if (numeric.cast(C, x) > numeric.cast(C, y)) return .gt;
    return .eq;
}
