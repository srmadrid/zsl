const meta = @import("../meta.zig");

/// Returns the sign of an float `x`.
///
/// ## Signature
/// ```zig
/// float.sign(x: X) X
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The float value to get the sign of.
///
/// ## Returns
/// `@TypeOf(x)`: The sign of `x`.
pub fn sign(x: anytype) @TypeOf(x) {
    const X: type = @TypeOf(x);

    comptime if (!meta.isNumeric(X) or meta.numericType(X) != .float)
        @compileError("zsl.float.sign: x must be an float, got \n\tx: " ++ @typeName(X) ++ "\n");

    return if (x > 0.0) 1.0 else if (x < 0.0) -1.0 else 0.0;
}
