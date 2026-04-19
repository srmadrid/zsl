const meta = @import("../meta.zig");

/// Returns the absolute value of an int `x`.
///
/// ## Signature
/// ```zig
/// int.abs(x: X) X
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The int value to get the absolute value of.
///
/// ## Returns
/// `@TypeOf(x)`: The absolute value of `x`.
pub fn abs(x: anytype) @TypeOf(x) {
    const X: type = @TypeOf(x);

    comptime if (!meta.isNumeric(X) or meta.numericType(X) != .int)
        @compileError("zsl.int.abs: x must be an int, got \n\tx: " ++ @typeName(X) ++ "\n");

    if (comptime X == comptime_int)
        return @abs(x);

    return @bitCast(@abs(x));
}
