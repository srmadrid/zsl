const meta = @import("../../meta.zig");
const numeric = @import("../../numeric.zig");

/// Returns the mathematical constant pi (`π`) for the given numeric type `N`.
/// This represents the ratio of a circle's circumference to its diameter
/// (`C/d ≈ 3.14159…`).
///
/// ## Arguments
/// * `N` (`comptime type`): The type to generate the `π` vaalue for.
///
/// ## Returns
/// `N`: The `π` value.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `N` must expose the `pi: N` declaration, or implement the `pi`
/// method. The expected signature and behavior of `pi` are as follows:
/// * `fn pi(anytype) N`: Returns the `π` value.
pub fn pi(comptime N: type) N {
    comptime if (!meta.isNumeric(N))
        @compileError("zsl.numeric.pi: " ++ @typeName(N) ++ " is not a numeric type");

    switch (comptime meta.numericType(N)) {
        .bool => @compileError("zsl.numeric.pi: not defined for " ++ @typeName(N) ++ "."),
        .int => @compileError("zsl.numeric.pi: not defined for " ++ @typeName(N) ++ "."),
        .float => return 3.14159265358979323846264338327950288419716939937510,
        .dyadic => {
            // π = 16 arctan(1/5) − 4 arctan(1/239)
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
                .exponent = -numeric.cast(N.Exponent, mantissa_bits - 2),
                .positive = true,
            };
        },
        .complex => return .{
            .re = numeric.pi(numeric.Re(N)),
            .im = numeric.cast(numeric.Im(N), 0),
        },
        .custom => {
            if (comptime @hasDecl(N, "pi") and @TypeOf(N.pi) == N)
                return N.pi
            else if (comptime meta.hasMethod(N, "pi", fn () N, &.{}))
                return N.pi()
            else
                @compileError("zsl.numeric.pi: " ++ @typeName(N) ++ " must expose a `pi: " ++ @typeName(N) ++ "` declaration, or implement `fn pi() " ++ @typeName(N) ++ "`");
        },
    }
}
