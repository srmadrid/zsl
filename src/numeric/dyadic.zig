//! Namespace for dyadic operations.

const dyadic = @This();

const std = @import("std");

const meta = @import("../meta.zig");
const numeric = @import("../numeric.zig");

/// Arbitrary-precision dyadic type.
pub fn Dyadic(mantissa_bits: u16, exponent_bits: u16) type {
    if (mantissa_bits == 0 or exponent_bits == 0 or
        mantissa_bits >= numeric.highest(u16) / 2 or exponent_bits >= numeric.highest(u16) / 2)
        @compileError(std.fmt.comptimePrint(
            "zsl.Dyadic: both mantissa_bits and exponent_bits must be non-zero and less than {}, got\n\tmantissa_bits: {}\n\texponent_bits: {}\n",
            .{ numeric.highest(u16) / 2, mantissa_bits, exponent_bits },
        ));

    return struct {
        mantissa: Mantissa,
        exponent: Exponent,
        positive: bool,

        // Type signature
        pub const is_numeric = true;

        pub const Accumulator = blk: {
            if (mantissa_bits <= 16)
                break :blk Dyadic(32, exponent_bits)
            else
                break :blk Dyadic(mantissa_bits, exponent_bits);
        };

        pub const Mantissa = @Int(.unsigned, mantissa_bits);
        pub const WideMantissa = @Int(.unsigned, 2 * mantissa_bits);
        pub const Exponent = @Int(.signed, exponent_bits);
        pub const WideExponent = @Int(.signed, 2 * exponent_bits);

        /// Initializes a dyadic from any numeric value.
        ///
        /// ## Arguments
        /// * `value` (`anytype`): The value to set the dyadic to. Must be a
        ///   numeric.
        ///
        /// ## Returns
        /// `Dyadic(mantissa_bits, exponent_bits)`: The new dyadic.
        pub fn initValue(value: anytype) Dyadic(mantissa_bits, exponent_bits) {
            const V: type = @TypeOf(value);

            comptime if (!meta.isNumeric(V))
                @compileError("zsl.Dyadic(mantissa_bits, exponent_bits).initValue: value must be a numeric, got \n\tvalue: " ++ @typeName(V) ++ "\n");

            switch (comptime meta.numericType(V)) {
                .bool => return if (value)
                    numeric.cast(Dyadic(mantissa_bits, exponent_bits), 1)
                else
                    numeric.cast(Dyadic(mantissa_bits, exponent_bits), 0),
                .int => {
                    if (value == 0)
                        return numeric.cast(Dyadic(mantissa_bits, exponent_bits), 0);

                    const UV = @Int(.unsigned, numeric.bitSize(value));
                    const abs_value = numeric.cast(UV, @abs(value));

                    const msb_pos_value: u16 = @typeInfo(UV).int.bits - 1 - @clz(abs_value);
                    const msb_pos_result: u16 = mantissa_bits - 1;

                    var mantissa: Mantissa = undefined;
                    var exponent: WideExponent = 0;
                    if (msb_pos_value > msb_pos_result) {
                        var shift: u16 = msb_pos_value - msb_pos_result;
                        const shift_minus_1 = shift - 1;

                        const shifted: UV = abs_value >> @intCast(shift);

                        const round_bit = (abs_value >> @intCast(shift_minus_1)) & 1;
                        const sticky = if (@ctz(abs_value) < shift_minus_1) @as(u1, 1) else 0;

                        var rounded: UV = shifted;
                        if (round_bit == 1 and (sticky == 1 or (shifted & 1) != 0))
                            rounded += 1;

                        if (comptime @typeInfo(UV).int.bits > mantissa_bits) {
                            const overflow = comptime 1 << mantissa_bits;
                            if (rounded == overflow) {
                                rounded >>= 1;
                                shift += 1;
                            }
                        }

                        mantissa = numeric.cast(Mantissa, rounded);
                        exponent +|= numeric.cast(WideExponent, shift);
                    } else {
                        const shift: u16 = msb_pos_result - msb_pos_value;
                        mantissa = numeric.cast(Mantissa, abs_value) << @intCast(shift);
                        exponent -|= numeric.cast(WideExponent, shift);
                    }

                    // Check for overflow
                    if (exponent >= numeric.highest(Exponent))
                        return .{
                            .mantissa = 0,
                            .exponent = numeric.highest(Exponent),
                            .positive = value >= 0,
                        };

                    // Check for underflow
                    if (exponent <= numeric.lowest(Exponent))
                        return .{
                            .mantissa = 0,
                            .exponent = numeric.lowest(Exponent),
                            .positive = value >= 0,
                        };

                    return .{
                        .mantissa = mantissa,
                        .exponent = numeric.cast(Exponent, exponent),
                        .positive = value >= 0,
                    };
                },
                .float => {
                    comptime if (V == f80)
                        @compileError("zsl.Dyadic(mantissa_bits, exponent_bits).initValue: f80 not yet supported");

                    const Bits = @Int(.unsigned, @typeInfo(V).float.bits);
                    const bits: Bits = @bitCast(value);

                    const f_mantissa_bits = comptime std.math.floatMantissaBits(V);
                    const f_exponent_bits = comptime std.math.floatExponentBits(V);
                    const bias = comptime (1 << (f_exponent_bits - 1)) - 1;
                    const exp_mask = comptime (1 << f_exponent_bits) - 1;
                    const mant_mask = comptime (1 << f_mantissa_bits) - 1;

                    const positive = (bits >> (f_mantissa_bits + f_exponent_bits)) == 0;
                    const biased_exp = (bits >> f_mantissa_bits) & exp_mask;
                    const frac = bits & mant_mask;

                    //NaN / Inf check
                    if (biased_exp == exp_mask) {
                        if (frac != 0)
                            return numeric.nan(Dyadic(mantissa_bits, exponent_bits));

                        return .{
                            .mantissa = 0,
                            .exponent = numeric.highest(Exponent),
                            .positive = positive,
                        };
                    }

                    // Zero check
                    if (biased_exp == 0 and frac == 0)
                        return .{
                            .mantissa = 0,
                            .exponent = numeric.lowest(Exponent),
                            .positive = positive,
                        };

                    const ExponentRaw = @Int(.signed, numeric.max(@typeInfo(WideExponent).int.bits, 32));

                    var raw_m: Bits = undefined;
                    var raw_e: ExponentRaw = undefined;
                    var msb_pos_value: u16 = undefined;

                    if (biased_exp == 0) {
                        // Subnormal: non-normalized
                        raw_m = frac;
                        raw_e = 1 - bias - f_mantissa_bits;
                        msb_pos_value = @typeInfo(Bits).int.bits - 1 - @clz(raw_m);
                    } else {
                        // Normal: implicitly normalized
                        raw_m = frac | (@as(Bits, 1) << f_mantissa_bits);
                        raw_e = numeric.cast(ExponentRaw, biased_exp) - bias - f_mantissa_bits;
                        msb_pos_value = f_mantissa_bits;
                    }

                    const msb_pos_result: u16 = mantissa_bits - 1;
                    var mantissa: Mantissa = undefined;
                    var exponent: ExponentRaw = raw_e;

                    if (msb_pos_value > msb_pos_result) {
                        var shift: u16 = msb_pos_value - msb_pos_result;
                        const shift_minus_1 = shift - 1;

                        const shifted: Bits = raw_m >> @intCast(shift);

                        const round_bit = (raw_m >> @intCast(shift_minus_1)) & 1;
                        const sticky = if (@ctz(raw_m) < shift_minus_1) @as(u1, 1) else 0;

                        var rounded: Bits = shifted;
                        if (round_bit == 1 and (sticky == 1 or (shifted & 1) != 0))
                            rounded += 1;

                        if (comptime @typeInfo(Bits).int.bits > mantissa_bits) {
                            const overflow = comptime 1 << mantissa_bits;
                            if (rounded == overflow) {
                                rounded >>= 1;
                                shift += 1;
                            }
                        }

                        mantissa = numeric.cast(Mantissa, rounded);
                        exponent += shift;
                    } else if (msb_pos_value < msb_pos_result) {
                        const shift: u16 = msb_pos_result - msb_pos_value;
                        const ShiftM = std.math.Log2Int(Mantissa);
                        mantissa = numeric.cast(Mantissa, raw_m) << @as(ShiftM, @intCast(shift));
                        exponent -= shift;
                    } else {
                        mantissa = numeric.cast(Mantissa, raw_m);
                    }

                    // Check for overflow
                    if (exponent >= numeric.highest(Exponent))
                        return .{
                            .mantissa = 0,
                            .exponent = numeric.highest(Exponent),
                            .positive = positive,
                        };

                    // Check for underflow
                    if (exponent <= numeric.lowest(Exponent))
                        return .{
                            .mantissa = 0,
                            .exponent = numeric.lowest(Exponent),
                            .positive = positive,
                        };

                    return .{
                        .mantissa = mantissa,
                        .exponent = numeric.cast(Exponent, exponent),
                        .positive = positive,
                    };
                },
                .dyadic => @compileError("zsl.Dyadic(mantissa_bits, exponent_bits).initValue: dyadics not yet supported"),
                .complex => return initValue(value.re),
                .custom => return numeric.cast(Dyadic(mantissa_bits, exponent_bits), value),
            }
        }

        pub fn toFloat(self: Dyadic(mantissa_bits, exponent_bits), comptime Float: type) Float {
            comptime if (!meta.isNumeric(Float) or meta.numericType(Float) != .float)
                @compileError("zsl.Dyadic(mantissa_bits, exponent_bits).toFloat: Float must be a float type, got \n\tFloat = " ++ @typeName(Float) ++ "\n");

            comptime if (Float == f80)
                @compileError("zsl.Dyadic(mantissa_bits, exponent_bits).toFloat: f80 not yet supported");

            if (self.isNan())
                return numeric.nan(Float);

            if (self.isInf())
                return if (self.positive) numeric.inf(Float) else -numeric.inf(Float);

            if (self.isZero())
                return if (self.positive) 0.0 else -0.0;

            const f_mantissa_bits = comptime std.math.floatMantissaBits(Float);
            const f_exponent_bits = comptime std.math.floatExponentBits(Float);
            const bias = comptime (1 << (f_exponent_bits - 1)) - 1;
            const max_biased = comptime (1 << f_exponent_bits) - 1;
            const frac_mask = comptime ((1 << f_mantissa_bits) - 1);

            const Bits = @Int(.unsigned, @typeInfo(Float).float.bits);
            const ExponentRaw = @Int(.signed, numeric.max(@typeInfo(WideExponent).int.bits, 32));

            const raw_e: ExponentRaw = numeric.cast(ExponentRaw, self.exponent) +| (mantissa_bits - 1);
            var biased_exp: ExponentRaw = raw_e +| bias;

            var right_shift: ExponentRaw = (numeric.cast(ExponentRaw, mantissa_bits) - 1) - f_mantissa_bits;

            if (biased_exp >= max_biased)
                return if (self.positive) std.math.inf(Float) else -std.math.inf(Float);

            if (biased_exp <= 0) {
                // Handle subnormals: exponent gets pinned to 0, and we shift right by the deficit
                right_shift += (1 - biased_exp);
                biased_exp = 0;
            }

            const Wide = @Int(.unsigned, numeric.max(mantissa_bits, f_mantissa_bits + 2));
            var m: Wide = undefined;

            if (right_shift < 0) {
                // Left shift, no rounding possible
                m = numeric.cast(Wide, self.mantissa) << @intCast(-right_shift);
            } else if (right_shift == 0) {
                // Exact alignment
                m = numeric.cast(Wide, self.mantissa);
            } else {
                const rs: u16 = numeric.cast(u16, right_shift);
                if (rs > mantissa_bits) {
                    // Completely shifted out of bounds
                    m = 0;
                } else if (rs == mantissa_bits) {
                    // Round bit is the MSB (which is 1). Sticky is the rest
                    const sticky_mask = comptime (1 << (mantissa_bits - 1)) - 1;
                    m = if ((self.mantissa & sticky_mask) != 0) 1 else 0;
                } else {
                    const shift_minus_1 = rs - 1;
                    const shifted = self.mantissa >> @intCast(rs);

                    const round_bit = (self.mantissa >> @intCast(shift_minus_1)) & 1;
                    const sticky = if (@ctz(self.mantissa) < shift_minus_1) @as(u1, 1) else 0;

                    m = numeric.cast(Wide, shifted);
                    if (round_bit == 1 and (sticky == 1 or (shifted & 1) != 0))
                        m += 1;
                }
            }

            // Renormalization
            if (biased_exp > 0) {
                const normal_threshold = comptime 1 << (f_mantissa_bits + 1);
                if (m >= normal_threshold) {
                    m >>= 1;
                    biased_exp += 1;
                    if (biased_exp >= max_biased)
                        return if (self.positive) std.math.inf(Float) else -std.math.inf(Float);
                }
            } else {
                const subnormal_threshold = comptime 1 << f_mantissa_bits;
                if (m >= subnormal_threshold) {
                    // Subnormal rounded up completely into a normal number
                    biased_exp = 1;
                }
            }

            const frac: Bits = numeric.cast(Bits, m & frac_mask);
            const exp_field: Bits = numeric.cast(Bits, biased_exp);
            const sign_bit: Bits = if (self.positive) 0 else 1;

            const float_bits: Bits = (sign_bit << (f_mantissa_bits + f_exponent_bits)) | (exp_field << f_mantissa_bits) | frac;

            return @bitCast(float_bits);
        }
    };
}
