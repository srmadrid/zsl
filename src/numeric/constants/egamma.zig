const meta = @import("../../meta.zig");
const numeric = @import("../../numeric.zig");

/// Returns the Euler-Mascheroni constant (`γ`) for the given numeric type `N`.
/// This represents the limiting difference between the harmonic series and the
/// natural logarithm (`limₙ→∞ (∑ₖ₌₁ⁿ 1/k - ln(n)) ≈ 0.57721…`).
///
/// ## Arguments
/// * `N` (`comptime type`): The type to generate the `γ` value for.
///
/// ## Returns
/// `N`: The `γ` value.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `N` must expose the `egamma: N` declaration, or implement the `egamma`
/// method. The expected signature and behavior of `egamma` are as follows:
/// * `fn egamma(anytype) N`: Returns the `γ` value.
pub fn egamma(comptime N: type) N {
    comptime if (!meta.isNumeric(N))
        @compileError("zsl.numeric.egamma: " ++ @typeName(N) ++ " is not a numeric type");

    switch (comptime meta.numericType(N)) {
        .bool => @compileError("zsl.numeric.egamma: not defined for " ++ @typeName(N) ++ "."),
        .int => @compileError("zsl.numeric.egamma: not defined for " ++ @typeName(N) ++ "."),
        .float => return 0.57721566490153286060651209008240243104215933593992,
        .dyadic => @compileError("zsl.numeric.egamma: not implemented for " ++ @typeName(N) ++ " yet."),
        .complex => return .{
            .re = numeric.egamma(numeric.Re(N)),
            .im = numeric.cast(numeric.Im(N), 0),
        },
        .custom => {
            if (comptime @hasDecl(N, "egamma") and @TypeOf(N.egamma) == N)
                return N.egamma
            else if (comptime meta.hasMethod(N, "egamma", fn () N, &.{}))
                return N.egamma()
            else
                @compileError("zsl.numeric.egamma: " ++ @typeName(N) ++ " must expose a `egamma: " ++ @typeName(N) ++ "` declaration, or implement `fn egamma() " ++ @typeName(N) ++ "`");
        },
    }
}
