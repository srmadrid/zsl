const meta = @import("../meta.zig");
const numeric = @import("../numeric.zig");

pub fn inf(comptime Dyadic: type) Dyadic {
    comptime if (!meta.isNumeric(Dyadic) or meta.numericType(Dyadic) != .dyadic)
        @compileError("zsl.dyadic.inf: Dyadic must be a dyadic type, got \n\nDyadic = " ++ @typeName(Dyadic) ++ "\n");

    return .{
        .mantissa = 0,
        .exponent = numeric.highest(Dyadic.Exponent),
        .positive = true,
    };
}
