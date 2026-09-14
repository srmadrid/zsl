const std = @import("std");

const meta = @import("../meta.zig");

/// Returns the maximum representable value (highest point on the number line)
/// for the given int type `Int`.
///
/// ## Arguments
/// * `Int` (`type`): The int type to generate the highest value for.
///
/// ## Returns
/// `Int`: The maximum representable value.
pub fn highest(comptime Int: type) Int {
    comptime if (!meta.isNumeric(Int) or meta.numericType(Int) != .int)
        @compileError("zsl.int.highest: Int must be an int type, got \n\tInt = " ++ @typeName(Int) ++ "\n");

    return std.math.maxInt(Int);
}
