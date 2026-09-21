const numeric = @import("../../../numeric.zig");

pub fn div(x: anytype, y: @TypeOf(x)) @TypeOf(x) {
    const R = @TypeOf(x);

    const mantissa_bits = @typeInfo(R.Mantissa).int.bits;

    // NaN check
    if (numeric.isNan(x) or numeric.isNan(y))
        return numeric.nan(R);

    const result_positive = x.positive == y.positive;

    // Infinity check
    if (numeric.isInf(x)) {
        if (numeric.isInf(y))
            return numeric.nan(R);

        return .{
            .mantissa = 0,
            .exponent = numeric.highest(R.Exponent),
            .positive = result_positive,
        };
    } else if (numeric.isInf(y)) {
        return .{
            .mantissa = 0,
            .exponent = numeric.lowest(R.Exponent),
            .positive = result_positive,
        };
    }

    // Zero check
    if (numeric.isZero(y)) {
        if (numeric.isZero(x))
            return numeric.nan(R); // 0 / 0 = NaN

        return .{
            .mantissa = 0,
            .exponent = numeric.highest(R.Exponent),
            .positive = result_positive,
        };
    } else if (numeric.isZero(x)) {
        return .{
            .mantissa = 0,
            .exponent = numeric.lowest(R.Exponent),
            .positive = result_positive,
        };
    }

    // Division
    const x_wide = numeric.cast(R.WideMantissa, x.mantissa) << @intCast(mantissa_bits);
    const y_wide = numeric.cast(R.WideMantissa, y.mantissa);

    const quotient = x_wide / y_wide;
    const remainder = x_wide % y_wide;

    var exponent = numeric.cast(R.WideExponent, x.exponent) - numeric.cast(R.WideExponent, y.exponent) - numeric.cast(R.WideExponent, mantissa_bits);
    var mantissa: R.Mantissa = undefined;
    var round_up = false;

    const q_msb_mask = comptime (1 << mantissa_bits);

    if ((quotient & q_msb_mask) != 0) {
        // MSB is at mantissa_bits. We must shift right by 1 to normalize
        mantissa = @truncate(quotient >> 1);
        exponent +|= 1;

        // Dropped bit is 1 AND (sticky remainder exists OR tie-to-even)
        round_up = (quotient & 1) == 1 and (remainder > 0 or (mantissa & 1) == 1);
    } else {
        // MSB is at mantissa_bits - 1. Fits perfectly
        mantissa = @truncate(quotient);
        const rem_doubled = remainder << 1;

        // > 0.5 OR (exactly 0.5 AND tie-to-even)
        round_up = (rem_doubled > y_wide) or (rem_doubled == y_wide and (mantissa & 1) == 1);
    }

    if (round_up) {
        const round = @addWithOverflow(mantissa, 1);
        mantissa = round[0];

        if (round[1] != 0) {
            // Mantissa overflowed during rounding (e.g., 1111 + 1 = 10000)
            mantissa = @as(R.Mantissa, 1) << (mantissa_bits - 1);
            exponent +|= 1;
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
