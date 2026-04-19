const std = @import("std");

const meta = @import("../meta.zig");

const numeric = @import("../numeric.zig");

const int = @import("../int.zig");

/// Generates a uniformly distributed integer in the closed interval
/// `[min, max]`.
pub fn discreteUniform(comptime N: type, min: N, max: N, prng: std.Random) N {
    comptime if (!meta.isNumeric(N) or meta.numericType(N) == .bool or !meta.isIntegral(N))
        @compileError("zsl.stats.discreteUniform: N must be a non-bool integral numeric type, got \n\tN = " ++ @typeName(N) ++ "\n");

    switch (comptime meta.numericType(N)) {
        .int => return prng.intRangeAtMost(N, min, max),
        .custom => {
            if (comptime !meta.hasMethod(N, "discreteUniform", fn (N, N, std.Random) N, &.{ N, N, std.Random }))
                @compileError("zsl.stats.discreteUniform: " ++ @typeName(N) ++ " must implement `fn discreteUniform(" ++ @typeName(N) ++ ", " ++ @typeName(N) ++ ", std.Random) " ++ @typeName(N) ++ "`");

            return N.discreteUniform(min, max, prng);
        },
        else => unreachable,
    }
}

/// Generates a standard uniform value in the range `[0.0, 1.0)` for
/// non-integral types.
pub fn standardUniform(comptime N: type, prng: std.Random) N {
    comptime if (!meta.isNumeric(N) or !meta.isReal(N) or !meta.isNonIntegral(N))
        @compileError("zsl.stats.standardUniform: N must be a real, non-integral numeric type, got \n\tN = " ++ @typeName(N) ++ "\n");

    switch (comptime meta.numericType(N)) {
        .float => switch (comptime N) {
            f16 => {
                const rand = prng.int(u24);
                const rand_lz = int.min(14, @clz(rand));

                const mantissa: u10 = @truncate(rand);
                const exponent = @as(u16, 14 - rand_lz) << 10;
                return @bitCast(exponent | mantissa);
            },
            f32, f64 => return prng.float(N),
            f80 => {
                const rand = prng.int(u80);
                var rand_lz: u80 = @clz(rand);
                if (rand_lz >= 17) {
                    rand_lz = 17;

                    while (true) {
                        const addl_rand_lz = @clz(prng.int(u64));
                        rand_lz += addl_rand_lz;

                        if (addl_rand_lz != 64) {
                            @branchHint(.likely);
                            break;
                        }

                        if (rand_lz >= 16382) {
                            rand_lz = 16382;
                            break;
                        }
                    }
                }

                const fraction = rand & 0x7FFFFFFFFFFFFFFF;
                const explicit_bit = if (rand_lz == 16382) @as(u80, 0) else (@as(u80, 1) << 63);
                const exponent = @as(u80, 16382 - rand_lz) << 64;
                return @bitCast(exponent | explicit_bit | fraction);
            },
            f128 => {
                const rand = prng.int(u128);
                var rand_lz: u128 = @clz(rand);
                if (rand_lz >= 16) {
                    rand_lz = 16;

                    while (true) {
                        const addl_rand_lz = @clz(prng.int(u64));
                        rand_lz += addl_rand_lz;

                        if (addl_rand_lz != 64) {
                            @branchHint(.likely);
                            break;
                        }

                        if (rand_lz >= 16382) {
                            rand_lz = 16382;
                            break;
                        }
                    }
                }

                const mantissa = rand & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                const exponent = (16382 - rand_lz) << 112;
                return @bitCast(exponent | mantissa);
            },
            else => unreachable,
        },
        .dyadic => {
            const mantissa_bits = @typeInfo(N.Mantissa).int.bits;

            const wide_min_exp = numeric.cast(N.WideExponent, std.math.minInt(N.Exponent));
            const wide_mantissa_bits = numeric.cast(N.WideExponent, mantissa_bits);

            if (-wide_mantissa_bits <= wide_min_exp) {
                return .{
                    .mantissa = 0,
                    .exponent = std.math.minInt(N.Exponent),
                    .positive = true,
                };
            }

            const max_lz = -wide_min_exp - wide_mantissa_bits;
            var lz: N.WideExponent = 0;

            while (true) {
                const chunk = prng.int(u64);
                lz += @clz(chunk);

                if (chunk != 0)
                    break;

                if (lz >= max_lz)
                    break;
            }

            if (lz >= max_lz) {
                return .{
                    .mantissa = 0,
                    .exponent = std.math.minInt(N.Exponent),
                    .positive = true,
                };
            }

            const exponent = numeric.cast(N.Exponent, -wide_mantissa_bits - lz);
            const msb_mask = @as(N.Mantissa, 1) << (mantissa_bits - 1);
            const mantissa = prng.int(N.Mantissa) | msb_mask;

            return .{
                .mantissa = mantissa,
                .exponent = exponent,
                .positive = true,
            };
        },
        .custom => {
            if (comptime !meta.hasMethod(N, "standardUniform", fn (std.Random) N, &.{std.Random}))
                @compileError("zsl.stats.standardUniform: " ++ @typeName(N) ++ " must implement `fn standardUniform(std.Random) " ++ @typeName(N) ++ "`");

            return N.standardUniform(prng);
        },
        else => unreachable,
    }
}
