const std = @import("std");

const numeric = @import("../../../numeric.zig");

pub fn fma(x: anytype, y: @TypeOf(x), z: @TypeOf(x)) @TypeOf(x) {
    const R = @TypeOf(x);

    const mantissa_bits = @typeInfo(R.Mantissa).int.bits;

    // NaN check
    if (numeric.isNan(x) or numeric.isNan(y) or numeric.isNan(z))
        return numeric.nan(R);

    const xy_positive = x.positive == y.positive;

    // Infinity check
    if (numeric.isInf(x) or numeric.isInf(y)) {
        if ((numeric.isInf(x) and numeric.isZero(y)) or (numeric.isZero(x) and numeric.isInf(y)))
            return numeric.nan(R); // Inf * 0 or 0 * Inf = NaN regardless of z

        if (numeric.isInf(z) and z.positive != xy_positive)
            return numeric.nan(R); // (±Inf) + (∓Inf) = NaN

        return .{
            .mantissa = 0,
            .exponent = numeric.highest(R.Exponent),
            .positive = xy_positive,
        };
    } else if (numeric.isInf(z)) {
        return z;
    }

    // Zero check
    if (numeric.isZero(x) or numeric.isZero(y)) {
        if (numeric.isZero(z))
            return .{
                .mantissa = 0,
                .exponent = numeric.lowest(R.Exponent),
                .positive = xy_positive or z.positive,
            };

        return z;
    }

    if (numeric.isZero(z))
        return numeric.mul(x, y);

    // Fused multiply-add (single rounding)
    var p_mant = numeric.cast(R.WideMantissa, x.mantissa) * numeric.cast(R.WideMantissa, y.mantissa);
    var p_exp = numeric.cast(R.WideExponent, x.exponent) + numeric.cast(R.WideExponent, y.exponent);

    // Check for MSB position
    if ((p_mant >> (2 * mantissa_bits - 1)) == 0) {
        p_mant <<= 1;
        p_exp -= 1;
    }

    const z_mant = numeric.cast(R.WideMantissa, z.mantissa) << @intCast(mantissa_bits);
    const z_exp = numeric.cast(R.WideExponent, z.exponent) - numeric.cast(R.WideExponent, mantissa_bits);

    // Order by magnitude
    const p_larger = if (p_exp != z_exp) p_exp > z_exp else p_mant >= z_mant;
    const larger_mant = if (p_larger) p_mant else z_mant;
    const larger_exp = if (p_larger) p_exp else z_exp;
    const larger_pos = if (p_larger) xy_positive else z.positive;
    const smaller_mant = if (p_larger) z_mant else p_mant;
    const smaller_exp = if (p_larger) z_exp else p_exp;
    const smaller_pos = if (p_larger) z.positive else xy_positive;

    // Align smaller to larger
    const exp_diff = larger_exp - smaller_exp;
    var smaller_shifted = smaller_mant;

    // frac holds the exact bits shifted out of smaller_mant, aligned to the MSB
    var frac: R.WideMantissa = 0;
    var sticky: u1 = 0;

    if (exp_diff >= 2 * mantissa_bits) {
        smaller_shifted = 0;
        sticky = 1; // smaller_mant is strictly nonzero here
    } else if (exp_diff > 0) {
        const shift = numeric.cast(std.math.Log2Int(R.WideMantissa), exp_diff);
        smaller_shifted = smaller_mant >> shift;

        const shifted_out = smaller_mant & ((@as(R.WideMantissa, 1) << shift) - 1);
        if (shifted_out != 0) {
            frac = shifted_out << @intCast(2 * mantissa_bits - shift);
        }
    }

    // Add (same sign) or subtract (opposite sign)
    var result_mant: R.WideMantissa = undefined;
    var result_exp = larger_exp;

    if (larger_pos == smaller_pos) {
        const sum_ov = @addWithOverflow(larger_mant, smaller_shifted);
        result_mant = sum_ov[0];
        if (sum_ov[1] != 0) {
            // Shift right to accommodate carry, pushing LSB into frac
            sticky |= @intCast(frac & 1);
            frac = (frac >> 1) | (@as(R.WideMantissa, @intCast(result_mant & 1)) << @intCast(2 * mantissa_bits - 1));
            result_mant = (result_mant >> 1) | (@as(R.WideMantissa, 1) << @intCast(2 * mantissa_bits - 1));
            result_exp +|= 1;
        }
    } else {
        var diff = larger_mant - smaller_shifted;

        if (frac != 0 or sticky == 1) {
            diff -= 1; // Borrow 1 from the integer part

            // Compute the new fractional part
            frac = if (sticky == 1) ~frac else ~frac +% 1;
        }

        if (diff == 0 and frac == 0) {
            return .{
                .mantissa = 0,
                .exponent = numeric.lowest(R.Exponent),
                .positive = true, // Exact zero is +0.0
            };
        }

        // Renormalize
        if (diff == 0) {
            // Massive cancellation: the result lives entirely in the fractional part
            const lz = @clz(frac);
            result_mant = frac << @intCast(lz);
            result_exp -|= numeric.cast(R.WideExponent, lz + 1);
            frac = 0;
        } else {
            const lz = @clz(diff);
            diff <<= @intCast(lz);
            if (lz > 0) {
                // Pull the top lz bits of frac up into the bottom of diff
                diff |= frac >> @intCast(2 * mantissa_bits - lz);
                frac <<= @intCast(lz);
            }

            result_mant = diff;
            result_exp -|= numeric.cast(R.WideExponent, lz);
        }
    }

    // Restore sticky
    if (frac != 0)
        sticky = 1;

    const remainder_mask = comptime ((1 << mantissa_bits) - 1);
    const halfway_mask = comptime (1 << (mantissa_bits - 1));

    var mantissa: R.Mantissa = @truncate(result_mant >> @intCast(mantissa_bits));
    const remainder = result_mant & remainder_mask;
    var final_exp = result_exp +| numeric.cast(R.WideExponent, mantissa_bits);
    const round_up = (remainder > halfway_mask) or (remainder == halfway_mask and (sticky == 1 or (mantissa & 1) == 1));

    if (round_up) {
        const inc = @addWithOverflow(mantissa, 1);
        mantissa = inc[0];
        if (inc[1] != 0) {
            mantissa = @as(R.Mantissa, 1) << (mantissa_bits - 1);
            final_exp +|= 1;
        }
    }

    // Check for overflow
    if (final_exp >= numeric.highest(R.Exponent))
        return .{
            .mantissa = 0,
            .exponent = numeric.highest(R.Exponent),
            .positive = larger_pos,
        };

    // Check for underflow
    if (final_exp <= numeric.lowest(R.Exponent))
        return .{
            .mantissa = 0,
            .exponent = numeric.lowest(R.Exponent),
            .positive = larger_pos,
        };

    return .{
        .mantissa = mantissa,
        .exponent = numeric.cast(R.Exponent, final_exp),
        .positive = larger_pos,
    };
}
