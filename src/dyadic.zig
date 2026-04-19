//! Namespace for dyadic operations.

const dyadic = @This();

const std = @import("std");

const meta = @import("meta.zig");
const Cmp = meta.Cmp;

const numeric = @import("numeric.zig");

const int = @import("int.zig");

/// Arbitrary-precision dyadic type.
pub fn Dyadic(mantissa_bits: u16, exponent_bits: u16) type {
    if (mantissa_bits == 0 or exponent_bits == 0 or
        mantissa_bits >= int.maxVal(u16) / 2 or exponent_bits >= int.maxVal(u16) / 2)
        @compileError(std.fmt.comptimePrint(
            "zsl.Dyadic: both mantissa_bits and exponent_bits must be non-zero and less than {}, got\n\tmantissa_bits: {}\n\texponent_bits: {}\n",
            .{ int.maxVal(u16) / 2, mantissa_bits, exponent_bits },
        ));

    return struct {
        mantissa: Mantissa,
        exponent: Exponent,
        positive: bool,

        // Type signature
        pub const is_numeric = true;
        pub const is_dyadic = true;
        pub const is_real_type = true;
        pub const is_signed = true;

        pub const Accumulator = blk: {
            if (mantissa_bits <= 16)
                break :blk Dyadic(32, exponent_bits)
            else
                break :blk Dyadic(mantissa_bits, exponent_bits);
        };

        pub const Mantissa = @Int(.unsigned, mantissa_bits);
        const WideMantissa = @Int(.unsigned, 2 * mantissa_bits);
        pub const Exponent = @Int(.signed, exponent_bits);
        const WideExponent = @Int(.signed, 2 * exponent_bits);

        // Constants
        pub const inf: Dyadic(mantissa_bits, exponent_bits) = .{ .mantissa = 0, .exponent = int.maxVal(Exponent), .positive = true };
        pub const nan: Dyadic(mantissa_bits, exponent_bits) = .{ .mantissa = 1, .exponent = int.maxVal(Exponent), .positive = true };
        pub const zero: Dyadic(mantissa_bits, exponent_bits) = .{ .mantissa = 0, .exponent = int.minVal(Exponent), .positive = true };
        pub const one: Dyadic(mantissa_bits, exponent_bits) = .{ .mantissa = @as(Mantissa, 1) << (mantissa_bits - 1), .exponent = 1 - numeric.cast(Exponent, mantissa_bits) };

        pub fn isInf(self: Dyadic(mantissa_bits, exponent_bits)) bool {
            return self.exponent == int.maxVal(Exponent) and self.mantissa == 0;
        }

        pub fn isNan(self: Dyadic(mantissa_bits, exponent_bits)) bool {
            return self.exponent == int.maxVal(Exponent) and self.mantissa != 0;
        }

        pub fn isZero(self: Dyadic(mantissa_bits, exponent_bits)) bool {
            return self.exponent == int.minVal(Exponent) and self.mantissa == 0;
        }

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
                .bool => if (value) .one else .zero,
                .int => {
                    var result: Dyadic(mantissa_bits, exponent_bits) = .{
                        .mantissa = numeric.cast(Mantissa, int.abs(value)),
                        .exponent = 0,
                        .positive = value >= 0,
                    };
                    result.normalize();
                    return result;
                },
                .float, .dyadic => {},
                .complex => return initValue(value.re),
                .custom => return numeric.cast(Dyadic(mantissa_bits, exponent_bits), value),
            }
        }

        /// Normalizes the dyadic in place, ensuring the mantissa is
        /// left-aligned (i.e., the most significant bit is set).
        ///
        /// ## Arguments
        /// * `self` (`*Dyadic(mantissa_bits, exponent_bits)`): A pointer to the
        ///   dyadic to normalize.
        ///
        /// ## Returns
        /// `void`
        pub fn normalize(self: *Dyadic(mantissa_bits, exponent_bits)) void {
            if (self.mantissa == 0) {
                self.exponent = int.minVal(Exponent);
                return;
            }

            const lz = @clz(self.mantissa);
            self.mantissa <<= lz;
            self.exponent -|= numeric.cast(Exponent, lz);

            if (self.exponent == int.minVal(Exponent))
                self.mantissa = 0;

            return;
        }

        pub fn add(x: Dyadic(mantissa_bits, exponent_bits), y: Dyadic(mantissa_bits, exponent_bits)) Dyadic(mantissa_bits, exponent_bits) {
            // NaN check
            if (x.isNan() or y.isNan())
                return .nan;

            // Infinity check
            if (x.isInf()) {
                if (y.isInf()) {
                    if (x.positive == y.positive)
                        return x
                    else
                        return .nan;
                } else {
                    return x;
                }
            } else if (y.isInf()) {
                return y;
            }

            // Zero check
            if (x.isZero())
                return y
            else if (y.isZero())
                return x;

            // Addition or subtraction
            const cmp_abs: meta.Cmp = x.abs().cmp(y.abs());
            if (x.positive == y.positive) {
                var result: Dyadic(mantissa_bits, exponent_bits) =
                    if (cmp_abs == .gt)
                        _addAbs(x, y)
                    else
                        _addAbs(y, x);
                result.positive = x.positive;
                return result;
            }

            if (cmp_abs == .eq)
                return .zero;

            var result: Dyadic(mantissa_bits, exponent_bits) =
                if (cmp_abs == .gt)
                    _subAbs(x, y)
                else
                    _subAbs(y, x);
            result.positive = if (cmp_abs == .gt) x.positive else y.positive;
            return result;
        }

        pub fn sub(x: Dyadic(mantissa_bits, exponent_bits), y: Dyadic(mantissa_bits, exponent_bits)) Dyadic(mantissa_bits, exponent_bits) {
            return x.add(y.neg());
        }

        fn _addAbs(x: Dyadic(mantissa_bits, exponent_bits), y: Dyadic(mantissa_bits, exponent_bits)) Dyadic(mantissa_bits, exponent_bits) {
            // |x| >= |y|, so exponent difference is non-negative
            const exp_diff: WideExponent = numeric.cast(WideExponent, x.exponent) - numeric.cast(WideExponent, y.exponent);

            const x_wide: WideMantissa = numeric.cast(WideMantissa, x.mantissa) << @intCast(mantissa_bits);
            const y_wide: WideMantissa = numeric.cast(WideMantissa, y.mantissa) << @intCast(mantissa_bits);

            var y_shifted: WideMantissa = undefined;
            var sticky: u1 = 0;
            if (exp_diff >= 2 * mantissa_bits) {
                y_shifted = 0;
                sticky = 1;
            } else {
                y_shifted = y_wide >> @intCast(exp_diff);

                if ((y_wide & ((@as(WideMantissa, 1) << @intCast(exp_diff)) - 1)) != 0)
                    sticky = 1;
            }

            const sum_ov = @addWithOverflow(x_wide, y_shifted);
            var sum: WideMantissa = sum_ov[0];
            const carry: u1 = sum_ov[1];
            var exponent: Exponent = x.exponent;
            if (carry != 0) {
                if ((sum & 1) != 0)
                    sticky = 1;

                sum >>= 1;
                sum |= (@as(WideMantissa, 1) << (mantissa_bits * 2 - 1));
                exponent +|= 1;
            }

            var mantissa: Mantissa = @truncate(sum >> @intCast(mantissa_bits));
            const remainder: WideMantissa = sum & ((@as(WideMantissa, 1) << @intCast(mantissa_bits)) - 1);
            const halfway: WideMantissa = @as(WideMantissa, 1) << @intCast(mantissa_bits - 1);
            var round_up = false;
            if (remainder > halfway) {
                round_up = true;
            } else if (remainder == halfway) {
                // Tie case
                if (sticky == 1 or (mantissa & 1) == 1)
                    round_up = true;
            }

            if (round_up) {
                const round = @addWithOverflow(mantissa, 1);
                mantissa = round[0];

                if (round[1] != 0) {
                    mantissa = @as(Mantissa, 1) << (mantissa_bits - 1);
                    exponent +|= 1;
                }
            }

            // Check for overflow
            if (exponent == int.maxVal(Exponent))
                return .{
                    .mantissa = 0,
                    .exponent = int.maxVal(Exponent),
                    .positive = true,
                };

            return .{
                .mantissa = mantissa,
                .exponent = exponent,
                .positive = true,
            };
        }

        fn _subAbs(x: Dyadic(mantissa_bits, exponent_bits), y: Dyadic(mantissa_bits, exponent_bits)) Dyadic(mantissa_bits, exponent_bits) {
            // |x| >= |y|, so exponent difference is non-negative
            const exp_diff: WideExponent = numeric.cast(WideExponent, x.exponent) - numeric.cast(WideExponent, y.exponent);

            const x_wide: WideMantissa = numeric.cast(WideMantissa, x.mantissa) << @intCast(mantissa_bits);
            const y_wide: WideMantissa = numeric.cast(WideMantissa, y.mantissa) << @intCast(mantissa_bits);

            var y_shifted: WideMantissa = undefined;
            var sticky: u1 = 0;
            if (exp_diff >= 2 * mantissa_bits) {
                y_shifted = 0;
                sticky = 1;
            } else {
                y_shifted = y_wide >> @intCast(exp_diff);

                if ((y_wide & ((@as(WideMantissa, 1) << @intCast(exp_diff)) - 1)) != 0)
                    sticky = 1;
            }

            var diff: WideMantissa = x_wide - y_shifted;
            if (sticky == 1)
                diff -= 1;

            if (diff == 0)
                return .zero;

            const lz = @clz(diff);

            var exponent: WideExponent = numeric.cast(WideExponent, x.exponent) - numeric.cast(WideExponent, lz);
            var mantissa: Mantissa = @truncate((diff << @intCast(lz)) >> @intCast(mantissa_bits));
            const remainder: WideMantissa = (diff << @intCast(lz)) & ((@as(WideMantissa, 1) << @intCast(mantissa_bits)) - 1);
            const halfway: WideMantissa = @as(WideMantissa, 1) << @intCast(mantissa_bits - 1);
            var round_up = false;
            if (remainder > halfway) {
                round_up = true;
            } else if (remainder == halfway) {
                // Tie case
                if (sticky == 1 or (mantissa & 1) == 1)
                    round_up = true;
            }

            if (round_up) {
                const round = @addWithOverflow(mantissa, 1);
                mantissa = round[0];

                if (round[1] != 0) {
                    mantissa = @as(Mantissa, 1) << (mantissa_bits - 1);
                    exponent +|= 1;
                }
            }

            // Check for underflow
            if (exponent <= int.minVal(Exponent))
                return .zero;

            return .{
                .mantissa = mantissa,
                .exponent = numeric.cast(Exponent, exponent),
                .positive = true,
            };
        }

        pub fn mul(x: Dyadic(mantissa_bits, exponent_bits), y: Dyadic(mantissa_bits, exponent_bits)) Dyadic(mantissa_bits, exponent_bits) {
            // NaN check
            if (x.isNan() or y.isNan())
                return .nan;

            // Infinity check
            if (x.isInf()) {
                if (y.isZero())
                    return .nan // Inf * 0 = NaN
                else
                    return .{
                        .mantissa = 0,
                        .exponent = int.maxVal(Exponent),
                        .positive = x.positive == y.positive,
                    };
            } else if (y.isInf()) {
                if (x.isZero())
                    return .nan // 0 * Inf = NaN
                else
                    return .{
                        .mantissa = 0,
                        .exponent = int.maxVal(Exponent),
                        .positive = x.positive == y.positive,
                    };
            }

            // Zero check
            if (x.isZero() or y.isZero())
                return .{
                    .mantissa = 0,
                    .exponent = int.minVal(Exponent),
                    .positive = x.positive == y.positive,
                };

            // Multiplication

            // MSB will be at bit position mantissa_bits * 2 - 1 or mantissa_bits * 2 - 2
            const product: WideMantissa = numeric.cast(WideMantissa, x.mantissa) * numeric.cast(WideMantissa, y.mantissa);
            var exponent: WideExponent = numeric.cast(WideExponent, x.exponent) + numeric.cast(WideExponent, y.exponent) + numeric.cast(WideExponent, mantissa_bits - 1);

            var mantissa: Mantissa = undefined;
            var remainder: WideMantissa = undefined;
            var halfway: WideMantissa = undefined;
            if ((product & (@as(WideMantissa, 1) << @intCast(mantissa_bits * 2 - 1))) != 0) {
                // MSB at mantissa_bits * 2 - 1
                mantissa = @truncate(product >> @intCast(mantissa_bits));
                remainder = product & ((@as(WideMantissa, 1) << @intCast(mantissa_bits)) - 1);
                halfway = @as(WideMantissa, 1) << @intCast(mantissa_bits - 1);
                exponent +|= 1;
            } else {
                // MSB at mantissa_bits * 2 - 2
                mantissa = @truncate(product >> @intCast(mantissa_bits - 1));
                remainder = product & ((@as(WideMantissa, 1) << @intCast(mantissa_bits - 1)) - 1);
                halfway = @as(WideMantissa, 1) << @intCast(mantissa_bits - 2);
            }

            if (remainder > halfway or (remainder == halfway and (mantissa & 1) == 1)) {
                const round = @addWithOverflow(mantissa, 1);
                mantissa = round[0];

                if (round[1] != 0) {
                    mantissa = @as(Mantissa, 1) << (mantissa_bits - 1);
                    exponent +|= 1;
                }
            }

            // Check for overflow
            if (exponent >= int.maxVal(Exponent))
                return .{
                    .mantissa = 0,
                    .exponent = int.maxVal(Exponent),
                    .positive = x.positive == y.positive,
                };

            // Check for underflow
            if (exponent <= int.minVal(Exponent))
                return .{
                    .mantissa = 0,
                    .exponent = int.minVal(Exponent),
                    .positive = x.positive == y.positive,
                };

            return .{
                .mantissa = mantissa,
                .exponent = numeric.cast(Exponent, exponent),
                .positive = x.positive == y.positive,
            };
        }

        pub fn div(x: Dyadic(mantissa_bits, exponent_bits), y: Dyadic(mantissa_bits, exponent_bits)) Dyadic(mantissa_bits, exponent_bits) {
            // NaN check
            if (x.isNan() or y.isNan())
                return .nan;

            // Infinity check
            if (x.isInf()) {
                if (y.isInf()) // Inf / Inf = NaN
                    return .nan
                else // Inf / Finite = Inf
                    return .{
                        .mantissa = 0,
                        .exponent = int.maxVal(Exponent),
                        .positive = x.positive == y.positive,
                    };
            } else if (y.isInf()) { // Finite / Inf = 0
                return .{
                    .mantissa = 0,
                    .exponent = int.minVal(Exponent),
                    .positive = x.positive == y.positive,
                };
            }

            // Zero check
            if (y.isZero()) {
                if (x.isZero()) // 0 / 0 = NaN
                    return .nan
                else // Finite / 0 = Inf
                    return .{
                        .mantissa = 0,
                        .exponent = int.maxVal(Exponent),
                        .positive = x.positive == y.positive,
                    };
            } else if (x.isZero()) { // 0 / Finite = 0
                return .{
                    .mantissa = 0,
                    .exponent = int.minVal(Exponent),
                    .positive = x.positive == y.positive,
                };
            }

            // Division
            const x_wide: WideMantissa = numeric.cast(WideMantissa, x.mantissa) << @intCast(mantissa_bits);
            const y_wide: WideMantissa = numeric.cast(WideMantissa, y.mantissa);
            const quotient: WideMantissa = x_wide / y_wide;
            const remainder: WideMantissa = x_wide % y_wide;

            var exponent: WideExponent = numeric.cast(WideExponent, x.exponent) - numeric.cast(WideExponent, y.exponent) - numeric.cast(WideExponent, mantissa_bits);
            var mantissa: Mantissa = undefined;
            var round_up = false;
            if ((quotient & (@as(WideMantissa, 1) << @intCast(mantissa_bits))) != 0) {
                // MSB is at mantissa_bits. We must shift right by 1 to normalize.
                mantissa = @truncate(quotient >> 1);
                exponent +|= 1;

                const dropped_bit = quotient & 1;

                // If dropped_bit is 1, the discarded fraction is >= 0.5
                if (dropped_bit == 1) {
                    if (remainder > 0) {
                        round_up = true; // Strictly > 0.5
                    } else if ((mantissa & 1) == 1) {
                        round_up = true; // Exactly 0.5, round to nearest even
                    }
                }
            } else {
                // MSB is at mantissa_bits - 1. Fits perfectly.
                mantissa = @truncate(quotient);

                // Discarded fraction is remainder / y_wide. Check if it's >= 0.5
                const rem_doubled = remainder << 1;

                if (rem_doubled > y_wide) {
                    round_up = true;
                } else if (rem_doubled == y_wide) {
                    if ((mantissa & 1) == 1) {
                        round_up = true; // Exactly 0.5, round to nearest even
                    }
                }
            }

            if (round_up) {
                const round = @addWithOverflow(mantissa, 1);
                mantissa = round[0];

                if (round[1] != 0) {
                    // Mantissa overflowed during rounding (e.g., 1111 + 1 = 10000)
                    mantissa = @as(Mantissa, 1) << (mantissa_bits - 1);
                    exponent +|= 1;
                }
            }

            // Check for overflow
            if (exponent >= int.maxVal(Exponent))
                return .{
                    .mantissa = 0,
                    .exponent = int.maxVal(Exponent),
                    .positive = x.positive == y.positive,
                };

            // Check for underflow
            if (exponent <= int.minVal(Exponent))
                return .{
                    .mantissa = 0,
                    .exponent = int.minVal(Exponent),
                    .positive = x.positive == y.positive,
                };

            return .{
                .mantissa = mantissa,
                .exponent = numeric.cast(Exponent, exponent),
                .positive = x.positive == y.positive,
            };
        }

        pub fn cmp(x: Dyadic(mantissa_bits, exponent_bits), y: Dyadic(mantissa_bits, exponent_bits)) Cmp {
            // NaN check
            if (x.isNan()) {
                if (y.isNan())
                    return .eq
                else
                    return .gt;
            } else if (y.isNan()) {
                return .lt;
            }

            // Zero check (ignoring sign)
            if (x.isZero() and y.isZero())
                return .eq;

            // Sign check
            if (x.positive != y.positive) {
                if (x.positive)
                    return .gt
                else
                    return .lt;
            }

            // Infinity check
            if (x.isInf()) {
                if (y.isInf())
                    return .eq
                else
                    return if (x.positive) .gt else .lt;
            } else if (y.isInf()) {
                return if (x.positive) .lt else .gt;
            }

            // Exponent comparison
            if (x.exponent > y.exponent)
                return if (x.positive) .gt else .lt
            else if (x.exponent < y.exponent)
                return if (x.positive) .lt else .gt;

            // Mantissa comparison
            if (x.mantissa > y.mantissa)
                return if (x.positive) .gt else .lt
            else if (x.mantissa < y.mantissa)
                return if (x.positive) .lt else .gt;

            return .eq;
        }

        pub fn abs(self: Dyadic(mantissa_bits, exponent_bits)) Dyadic(mantissa_bits, exponent_bits) {
            return .{
                .mantissa = self.mantissa,
                .exponent = self.exponent,
                .positive = true,
            };
        }

        pub fn neg(self: Dyadic(mantissa_bits, exponent_bits)) Dyadic(mantissa_bits, exponent_bits) {
            return .{
                .mantissa = self.mantissa,
                .exponent = self.exponent,
                .positive = !self.positive,
            };
        }

        pub fn toFloat(comptime Float: type) Float {}
    };
}

pub const Coerce = @import("dyadic/coerce.zig").Coerce;

pub fn Add(comptime X: type, comptime Y: type) type {
    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or
        !meta.numericType(X).le(.dyadic) or !meta.numericType(Y).le(.dyadic) or
        (meta.numericType(X) != .dyadic and meta.numericType(Y) != .dyadic))
        @compileError("zsl.dyadic.add: at least one of x or y must be a dyadic, the other must be a bool, an int, a float or a dyadic, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    return dyadic.Coerce(X, Y);
}

/// Performs addition between two operands of dyadic, float, int or bool types,
/// where at least one operand must be of dyadic type. The result type is
/// determined by coercing the operand types, and the operation is performed by
/// casting both operands to the result type, then adding them.
///
/// ## Signature
/// ```zig
/// dyadic.add(x: X, y: Y) dyadic.Add(X, Y)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
///
/// ## Returns
/// `dyadic.Add(@TypeOf(x), @TypeOf(y))`: The result of the addition.
pub fn add(x: anytype, y: anytype) dyadic.Add(@TypeOf(x), @TypeOf(y)) {
    const R: type = Add(@TypeOf(x), @TypeOf(y));

    return R.add(numeric.cast(R, x), numeric.cast(R, y));
}

pub fn Sub(comptime X: type, comptime Y: type) type {
    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or
        !meta.numericType(X).le(.dyadic) or !meta.numericType(Y).le(.dyadic) or
        (meta.numericType(X) != .dyadic and meta.numericType(Y) != .dyadic))
        @compileError("zsl.dyadic.sub: at least one of x or y must be a dyadic, the other must be a bool, an int, a float or a dyadic, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    return dyadic.Coerce(X, Y);
}

/// Performs subtraction between two operands of dyadic, float, int or bool
/// types, where at least one operand must be of dyadic type. The result type is
/// determined by coercing the operand types, and the operation is performed by
/// casting both operands to the result type, then subtracting them.
///
/// ## Signature
/// ```zig
/// dyadic.sub(x: X, y: Y) dyadic.Sub(X, Y)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
///
/// ## Returns
/// `dyadic.Sub(@TypeOf(x), @TypeOf(y))`: The result of the subtraction.
pub fn sub(x: anytype, y: anytype) Sub(@TypeOf(x), @TypeOf(y)) {
    const R: type = Sub(@TypeOf(x), @TypeOf(y));

    return R.sub(numeric.cast(R, x), numeric.cast(R, y));
}

pub fn Mul(comptime X: type, comptime Y: type) type {
    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or
        !meta.numericType(X).le(.dyadic) or !meta.numericType(Y).le(.dyadic) or
        (meta.numericType(X) != .dyadic and meta.numericType(Y) != .dyadic))
        @compileError("zsl.dyadic.mul: at least one of x or y must be a dyadic, the other must be a bool, an int, a float or a dyadic, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    return dyadic.Coerce(X, Y);
}

/// Performs multiplication between two operands of dyadic, float, int or bool
/// types, where at least one operand must be of dyadic type. The result type is
/// determined by coercing the operand types, and the operation is performed by
/// casting both operands to the result type, then multiplication them.
///
/// ## Signature
/// ```zig
/// dyadic.mul(x: X, y: Y) dyadic.Mul(X, Y)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
///
/// ## Returns
/// `dyadic.Mul(@TypeOf(x), @TypeOf(y))`: The result of the multiplication.
pub fn mul(x: anytype, y: anytype) Mul(@TypeOf(x), @TypeOf(y)) {
    const R: type = Mul(@TypeOf(x), @TypeOf(y));

    return R.mul(numeric.cast(R, x), numeric.cast(R, y));
}

pub fn Fma(comptime X: type, comptime Y: type, comptime Z: type) type {
    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or !meta.isNumeric(Z) or
        !meta.numericType(X).le(.dyadic) or !meta.numericType(Y).le(.dyadic) or !meta.numericType(Z).le(.dyadic) or
        (meta.numericType(X) != .dyadic and meta.numericType(Y) != .dyadic and meta.numericType(Z) != .dyadic))
        @compileError("zsl.dyadic.fma: at least one of x, y or z must be a dyadic, the others must be bool, int, float or dyadic, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n\tz: " ++ @typeName(Z) ++ "\n");

    return dyadic.Coerce(X, numeric.Coerce(Y, Z));
}

/// Performs fused multiplication and addition (x * y + z) between three
/// operands of dyadic, float, int or bool types, where at least one operand
/// must be of dyadic type. The result type is determined by coercing the
/// operand types, and the operation is performed by casting all three operands
/// to the result type, then performing the fused operation.
///
/// ## Signature
/// ```zig
/// dyadic.fma(x: X, y: Y, z: Z) dyadic.Fma(X, Y, Z)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The left multiplication operand.
/// * `y` (`anytype`): The right multiplication operand.
/// * `z` (`anytype`): The addition operand.
///
/// ## Returns
/// `dyadic.Fma(@TypeOf(x), @TypeOf(y), @TypeOf(z))`: The result of the fused
/// multiplication and addition.
pub fn fma(x: anytype, y: anytype, z: anytype) dyadic.Fma(@TypeOf(x), @TypeOf(y), @TypeOf(z)) {
    const R: type = dyadic.Fma(@TypeOf(x), @TypeOf(y), @TypeOf(z));

    return R.fma(numeric.cast(R, x), numeric.cast(R, y), numeric.cast(R, z));
}

pub fn Div(comptime X: type, comptime Y: type) type {
    comptime if (!meta.isNumeric(X) or !meta.isNumeric(Y) or
        !meta.numericType(X).le(.dyadic) or !meta.numericType(Y).le(.dyadic) or
        (meta.numericType(X) != .dyadic and meta.numericType(Y) != .dyadic))
        @compileError("zsl.dyadic.div: at least one of x or y must be a dyadic, the other must be a bool, an int, a float or a dyadic, got\n\tx: " ++
            @typeName(X) ++ "\n\ty: " ++ @typeName(Y) ++ "\n");

    return dyadic.Coerce(X, Y);
}

/// Performs division between two operands of dyadic, float, int or bool types,
/// where at least one operand must be of dyadic type. The result type is
/// determined by coercing the operand types, and the operation is performed by
/// casting both operands to the result type, then dividing them.
///
/// ## Signature
/// ```zig
/// dyadic.div(x: X, y: Y) dyadic.Div(X, Y)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The left operand.
/// * `y` (`anytype`): The right operand.
///
/// ## Returns
/// `dyadic.Div(@TypeOf(x), @TypeOf(y))`: The result of the division.
pub fn div(x: anytype, y: anytype) Div(@TypeOf(x), @TypeOf(y)) {
    const R: type = Div(@TypeOf(x), @TypeOf(y));

    return numeric.cast(R, x).div(numeric.cast(R, y));
}

pub const sign = @import("dyadic/sign.zig").sign;
