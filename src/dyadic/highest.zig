const meta = @import("../meta.zig");
const numeric = @import("../numeric.zig");

pub fn highest(comptime Dyadic: type) Dyadic {
    comptime if (!meta.isNumeric(Dyadic) or meta.numericType(Dyadic) != .dyadic)
        @compileError("zsl.dyadic.highest: Dyadic must be a dyadic type, got \n\nDyadic = " ++ @typeName(Dyadic) ++ "\n");

    return .{
        .mantissa = numeric.highest(Dyadic.Mantissa),
        .exponent = numeric.highest(Dyadic.Exponent) - 1,
        .positive = true,
    };
}
