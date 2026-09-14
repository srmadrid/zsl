const meta = @import("../meta.zig");
const numeric = @import("../numeric.zig");

pub fn eps(comptime Dyadic: type) Dyadic {
    comptime if (!meta.isNumeric(Dyadic) or meta.numericType(Dyadic) != .dyadic)
        @compileError("zsl.dyadic.eps: Dyadic must be a dyadic type, got \n\nDyadic = " ++ @typeName(Dyadic) ++ "\n");

    const mantissa_bits = @typeInfo(Dyadic.Mantissa).int.bits;

    return .{
        .mantissa = 1 << (mantissa_bits - 1),
        .exponent = -numeric.cast(Dyadic.Exponent, 2 * (mantissa_bits - 1)),
        .positive = true,
    };
}
