const std = @import("std");

const numeric = @import("../../../numeric.zig");

pub fn order(x: anytype, y: @TypeOf(x)) std.math.Order {
    // NaN check
    if (numeric.isNan(x))
        return if (numeric.isNan(y)) .eq else .gt;

    if (numeric.isNan(y)) return .lt;

    // Zero check
    if (numeric.isZero(x) and numeric.isZero(y))
        return .eq;

    // Sign check
    if (x.positive != y.positive)
        return if (x.positive) .gt else .lt;

    // Signs equal, evaluate magnitude
    var mag_order: std.math.Order = .eq;

    if (numeric.isInf(x)) {
        mag_order = if (numeric.isInf(y)) .eq else .gt;
    } else if (numeric.isInf(y)) {
        mag_order = .lt;
    } else {
        mag_order = if (x.exponent != y.exponent)
            numeric.order(x.exponent, y.exponent)
        else
            numeric.order(x.mantissa, y.mantissa);
    }

    return if (x.positive) mag_order else mag_order.invert();
}
