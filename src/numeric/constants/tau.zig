const meta = @import("../../meta.zig");
const numeric = @import("../../numeric.zig");

/// Returns the mathematical constant tau (`τ`) for the given numeric type `N`.
/// This represents the ratio of a circle's circumference to its radius
/// (`C/r ≈ 6.28318…`, equivalent to `2π`).
///
/// ## Arguments
/// * `N` (`comptime type`): The type to generate the `τ` value for.
///
/// ## Returns
/// `N`: The `τ` value.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `N` must expose the `tau: N` declaration, or implement the `tau`
/// method. The expected signature and behavior of `tau` are as follows:
/// * `fn tau(anytype) N`: Returns the `τ` value.
pub fn tau(comptime N: type) N {
    comptime if (!meta.isNumeric(N))
        @compileError("zsl.numeric.tau: " ++ @typeName(N) ++ " is not a numeric type");

    switch (comptime meta.numericType(N)) {
        .bool => @compileError("zsl.numeric.tau: not defined for " ++ @typeName(N) ++ "."),
        .int => @compileError("zsl.numeric.tau: not defined for " ++ @typeName(N) ++ "."),
        .float => return 6.28318530717958647692528676655900576839433879875021,
        .dyadic => {
            // 2π = 32 arctan(1/5) − 8 arctan(1/239)
            const mantissa_bits = @typeInfo(N.Mantissa).int.bits;

            comptime var term1: N.WideMantissa = (1 << (2 * mantissa_bits - 1)) / 5;
            comptime var sum1: N.WideMantissa = term1;
            comptime var divisor: N.WideMantissa = 3;
            comptime var subtract: bool = true;
            inline while (true) {
                term1 /= 25; // 5² = 25
                if (term1 == 0)
                    break;

                if (subtract)
                    sum1 -= term1 / divisor
                else
                    sum1 += term1 / divisor;

                divisor += 2;
                subtract = !subtract;
            }

            comptime var term2: N.WideMantissa = (1 << (2 * mantissa_bits - 3)) / 239;
            comptime var sum2: N.WideMantissa = term2;
            divisor = 3;
            subtract = true;
            inline while (true) {
                term2 /= 57121; // 239² = 57121
                if (term2 == 0)
                    break;

                if (subtract)
                    sum2 -= term2 / divisor
                else
                    sum2 += term2 / divisor;

                divisor += 2;
                subtract = !subtract;
            }

            return .{
                .mantissa = @truncate((sum1 - sum2 + (1 << (mantissa_bits - 3 - 1))) >> (mantissa_bits - 3)),
                .exponent = -numeric.cast(N.Exponent, mantissa_bits - 3),
                .positive = true,
            };
        },
        .complex => return .{
            .re = numeric.tau(numeric.Re(N)),
            .im = numeric.cast(numeric.Im(N), 0),
        },
        .custom => {
            if (comptime @hasDecl(N, "tau") and @TypeOf(N.tau) == N)
                return N.tau
            else if (comptime meta.hasMethod(N, "tau", fn () N, &.{}))
                return N.tau()
            else
                @compileError("zsl.numeric.tau: " ++ @typeName(N) ++ " must expose a `tau: " ++ @typeName(N) ++ "` declaration, or implement `fn tau() " ++ @typeName(N) ++ "`");
        },
    }
}
