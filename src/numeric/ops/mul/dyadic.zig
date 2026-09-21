const numeric = @import("../../../numeric.zig");

pub fn mul(x: anytype, y: @TypeOf(x)) @TypeOf(x) {
    const R = @TypeOf(x);

    const mantissa_bits = @typeInfo(R.Mantissa).int.bits;

    // NaN check
    if (numeric.isNan(x) or numeric.isNan(y))
        return numeric.nan(R);

    const result_positive = x.positive == y.positive;

    // Infinity check
    if (numeric.isInf(x)) {
        if (numeric.isZero(y))
            return numeric.nan(R); // Inf * 0 = NaN

        return .{
            .mantissa = 0,
            .exponent = numeric.highest(R.Exponent),
            .positive = result_positive,
        };
    } else if (numeric.isInf(y)) {
        if (numeric.isZero(x))
            return numeric.nan(R); // 0 * Inf = NaN

        return .{
            .mantissa = 0,
            .exponent = numeric.highest(R.Exponent),
            .positive = result_positive,
        };
    }

    // Zero check
    if (numeric.isZero(x) or numeric.isZero(y))
        return .{
            .mantissa = 0,
            .exponent = numeric.lowest(R.Exponent),
            .positive = result_positive,
        };

    // Multiplication
    var product = numeric.cast(R.WideMantissa, x.mantissa) * numeric.cast(R.WideMantissa, y.mantissa);

    // Base exponent assumes the MSB landed at 2 * mantissa_bits - 1
    var exponent = numeric.cast(R.WideExponent, x.exponent) + numeric.cast(R.WideExponent, y.exponent) + numeric.cast(R.WideExponent, mantissa_bits);

    // Normalize: If the MSB is at 2 * mantissa_bits - 2, shift left to standardize it
    if ((product >> (mantissa_bits * 2 - 1)) == 0) {
        product <<= 1;
        exponent -= 1;
    }

    const halfway_mask = comptime (1 << (mantissa_bits - 1));
    const remainder_mask = comptime ((1 << mantissa_bits) - 1);

    var mantissa: R.Mantissa = @truncate(product >> @intCast(mantissa_bits));
    const remainder = product & remainder_mask;

    // Round to nearest, tie to even
    if (remainder > halfway_mask or (remainder == halfway_mask and (mantissa & 1) == 1)) {
        const round = @addWithOverflow(mantissa, 1);
        mantissa = round[0];

        if (round[1] != 0) {
            mantissa = @as(R.Mantissa, 1) << (mantissa_bits - 1);
            exponent += 1;
        }
    }

    // Check for overflow
    if (exponent >= numeric.highest(R.Exponent))
        return .{
            .mantissa = 0,
            .exponent = numeric.highest(R.Exponent),
            .positive = result_positive,
        };

    // Check for underflow
    if (exponent <= numeric.lowest(R.Exponent))
        return .{
            .mantissa = 0,
            .exponent = numeric.lowest(R.Exponent),
            .positive = result_positive,
        };

    return .{
        .mantissa = mantissa,
        .exponent = numeric.cast(R.Exponent, exponent),
        .positive = result_positive,
    };
}
