const std = @import("std");

const meta = @import("../meta.zig");

/// Returns the lowest representable value of the given int type `Int`.
///
/// ## Arguments
/// * `Int` (`type`): The int type to get the lowest value for.
///
/// ## Returns
/// `Int`: The minimum representable value of type `Int`.
pub fn lowest(comptime Int: type) Int {
    comptime if (!meta.isNumeric(Int) or meta.numericType(Int) != .int)
        @compileError("zsl.int.lowest: Int must be an int type, got \n\tInt = " ++ @typeName(Int) ++ "\n");

    return std.math.minInt(Int);
}
