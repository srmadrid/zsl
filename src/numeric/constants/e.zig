const meta = @import("../../meta.zig");
const numeric = @import("../../numeric.zig");

/// Returns Euler's number (`e`) for the given numeric type `N`. This represents
/// the base of the natural logarithm (`∑ₖ₌₀^∞ 1/k! ≈ 2.71828…`).
///
/// ## Arguments
/// * `N` (`comptime type`): The type to generate the `e` value for.
///
/// ## Returns
/// `N`: The `e` value.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `N` must expose the `e: N` declaration, or implement the `e`
/// method. The expected signature and behavior of `e` are as follows:
/// * `fn e(anytype) N`: Returns the `e` value.
pub fn e(comptime N: type) N {
    comptime if (!meta.isNumeric(N))
        @compileError("zsl.numeric.e: " ++ @typeName(N) ++ " is not a numeric type");

    switch (comptime meta.numericType(N)) {
        .bool => @compileError("zsl.numeric.e: not defined for " ++ @typeName(N) ++ "."),
        .int => @compileError("zsl.numeric.e: not defined for " ++ @typeName(N) ++ "."),
        .float => return 2.71828182845904523536028747135266249775724709369995,
        .dyadic => {
            // eˣ at x = 1, e = 1 + 1/1 + 1/2 + 1/6 + 1/24 …
            const mantissa_bits = @typeInfo(N.Mantissa).int.bits;

            comptime var term: N.WideMantissa = 1 << (2 * mantissa_bits - 2);
            comptime var sum: N.WideMantissa = term;
            comptime var divisor: N.WideMantissa = 1;
            inline while (true) {
                term /= divisor;
                if (term == 0)
                    break;

                sum += term;

                divisor += 1;
            }

            return .{
                .mantissa = @truncate((sum + (1 << (mantissa_bits - 1))) >> mantissa_bits),
                .exponent = -numeric.cast(N.Exponent, mantissa_bits - 2),
                .positive = true,
            };
        },
        .complex => return .{
            .re = numeric.e(numeric.Re(N)),
            .im = numeric.cast(numeric.Im(N), 0),
        },
        .custom => {
            if (comptime @hasDecl(N, "e") and @TypeOf(N.e) == N)
                return N.e
            else if (comptime meta.hasMethod(N, "e", fn () N, &.{}))
                return N.e()
            else
                @compileError("zsl.numeric.e: " ++ @typeName(N) ++ " must expose a `e: " ++ @typeName(N) ++ "` declaration, or implement `fn e() " ++ @typeName(N) ++ "`");
        },
    }
}
