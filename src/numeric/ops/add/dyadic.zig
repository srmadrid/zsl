const numeric = @import("../../../numeric.zig");

pub fn add(x: anytype, y: @TypeOf(x)) @TypeOf(x) {
    const R = @TypeOf(x);

    // NaN check
    if (numeric.isNan(x) or numeric.isNan(y))
        return numeric.nan(R);

    // Infinity check
    if (numeric.isInf(x)) {
        if (numeric.isInf(y)) {
            if (x.positive == y.positive)
                return x
            else
                return numeric.nan(R);
        } else {
            return x;
        }
    } else if (numeric.isInf(y)) {
        return y;
    }

    // Zero check
    if (numeric.isZero(x))
        return if (numeric.isZero(y))
            .{ .mantissa = 0, .exponent = numeric.lowest(R.Exponent), .positive = x.positive or y.positive }
        else
            y
    else if (numeric.isZero(y))
        return x;

    // Addition or subtraction
    const order_abs = if (x.exponent != y.exponent)
        numeric.order(x.exponent, y.exponent)
    else
        numeric.order(x.mantissa, y.mantissa);

    if (x.positive == y.positive) {
        var result =
            if (order_abs == .gt)
                _addAbs(x, y)
            else
                _addAbs(y, x);
        result.positive = x.positive;
        return result;
    }

    if (order_abs == .eq)
        return .zero;

    var result =
        if (order_abs == .gt)
            _subAbs(x, y)
        else
            _subAbs(y, x);
    result.positive = if (order_abs == .gt) x.positive else y.positive;
    return result;
}

fn _addAbs(x: anytype, y: @TypeOf(x)) @TypeOf(x) {
    const R = @TypeOf(x);

    const mantissa_bits = @typeInfo(R.Mantissa).int.bits;

    // |x| >= |y|, so exponent difference is non-negative
    const exp_diff = numeric.cast(R.WideExponent, x.exponent) - numeric.cast(R.WideExponent, y.exponent);

    const x_wide = numeric.cast(R.WideMantissa, x.mantissa) << @intCast(mantissa_bits);
    const y_wide = numeric.cast(R.WideMantissa, y.mantissa) << @intCast(mantissa_bits);

    var y_shifted: R.WideMantissa = undefined;
    var sticky: u1 = 0;
    if (exp_diff >= 2 * mantissa_bits) {
        y_shifted = 0;
        sticky = 1;
    } else {
        y_shifted = y_wide >> @intCast(exp_diff);

        if (@ctz(y_wide) < exp_diff)
            sticky = 1;
    }

    const sum_ov = @addWithOverflow(x_wide, y_shifted);
    var sum = sum_ov[0];
    const carry = sum_ov[1];
    var exponent = x.exponent;
    if (carry != 0) {
        if ((sum & 1) != 0)
            sticky = 1;

        sum >>= 1;
        sum |= (@as(R.WideMantissa, 1) << (mantissa_bits * 2 - 1));
        exponent +|= 1;
    }

    const remainder_mask = comptime ((1 << mantissa_bits) - 1);
    const halfway_mask = comptime (1 << (mantissa_bits - 1));

    var mantissa: R.Mantissa = @truncate(sum >> @intCast(mantissa_bits));
    const remainder = sum & remainder_mask;
    const round_up = (remainder > halfway_mask) or (remainder == halfway_mask and (sticky == 1 or (mantissa & 1) == 1));

    if (round_up) {
        const round = @addWithOverflow(mantissa, 1);
        mantissa = round[0];

        if (round[1] != 0) {
            mantissa = @as(R.Mantissa, 1) << (mantissa_bits - 1);
            exponent +|= 1;
        }
    }

    // Check for overflow
    if (exponent == numeric.highest(R.Exponent))
        return .{
            .mantissa = 0,
            .exponent = numeric.highest(R.Exponent),
            .positive = true,
        };

    return .{
        .mantissa = mantissa,
        .exponent = exponent,
        .positive = true,
    };
}

fn _subAbs(x: anytype, y: @TypeOf(x)) @TypeOf(x) {
    const R = @TypeOf(x);

    const mantissa_bits = @typeInfo(R.Mantissa).int.bits;

    // |x| >= |y|, so exponent difference is non-negative
    const exp_diff = numeric.cast(R.WideExponent, x.exponent) - numeric.cast(R.WideExponent, y.exponent);

    const x_wide = numeric.cast(R.WideMantissa, x.mantissa) << @intCast(mantissa_bits);
    const y_wide = numeric.cast(R.WideMantissa, y.mantissa) << @intCast(mantissa_bits);

    var y_shifted: R.WideMantissa = undefined;
    var sticky: u1 = 0;
    if (exp_diff >= 2 * mantissa_bits) {
        y_shifted = 0;
        sticky = 1;
    } else {
        y_shifted = y_wide >> @intCast(exp_diff);

        if (@ctz(y_wide) < exp_diff)
            sticky = 1;
    }

    var diff: R.WideMantissa = x_wide - y_shifted;
    if (sticky == 1)
        diff -= 1;

    if (diff == 0)
        return .zero;

    const lz = @clz(diff);

    var exponent = numeric.cast(R.WideExponent, x.exponent) - numeric.cast(R.WideExponent, lz);

    const remainder_mask = comptime ((1 << mantissa_bits) - 1);
    const halfway_mask = comptime (1 << (mantissa_bits - 1));

    const shifted_diff = diff << @intCast(lz);

    var mantissa: R.Mantissa = @truncate(shifted_diff >> @intCast(mantissa_bits));
    const remainder = shifted_diff & remainder_mask;
    const round_up = (remainder > halfway_mask) or (remainder == halfway_mask and (sticky == 1 or (mantissa & 1) == 1));

    if (round_up) {
        const round = @addWithOverflow(mantissa, 1);
        mantissa = round[0];

        if (round[1] != 0) {
            mantissa = @as(R.Mantissa, 1) << (mantissa_bits - 1);
            exponent +|= 1;
        }
    }

    // Check for underflow
    if (exponent <= numeric.lowest(R.Exponent))
        return numeric.cast(R, 0);

    return .{
        .mantissa = mantissa,
        .exponent = numeric.cast(R.Exponent, exponent),
        .positive = true,
    };
}
