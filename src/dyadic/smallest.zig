const meta = @import("../meta.zig");
const numeric = @import("../numeric.zig");

pub fn smallest(comptime Dyadic: type) Dyadic {
    comptime if (!meta.isNumeric(Dyadic) or meta.numericType(Dyadic) != .dyadic)
        @compileError("zsl.dyadic.smallest: Dyadic must be a dyadic type, got \n\nDyadic = " ++ @typeName(Dyadic) ++ "\n");

    const mantissa_bits = @typeInfo(Dyadic.Mantissa).int.bits;

    return .{
        .mantissa = 1 << (mantissa_bits - 1),
        .exponent = numeric.lowest(Dyadic.Exponent),
        .positive = true,
    };
}
