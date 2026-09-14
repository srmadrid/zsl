const meta = @import("../meta.zig");

/// Returns the smallest positive magnitude strictly greater than zero of the
/// given int type `Int`.
///
/// ## Arguments
/// * `Int` (`type`): The int type to get the minimum value for.
///
/// ## Returns
/// `Int`: The minimum representable value of type `Int`.
pub fn smallest(comptime Int: type) Int {
    comptime if (!meta.isNumeric(Int) or meta.numericType(Int) != .int)
        @compileError("zsl.int.smallest: Int must be an int type, got \n\tInt = " ++ @typeName(Int) ++ "\n");

    return 1;
}
