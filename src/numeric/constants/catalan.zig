const meta = @import("../../meta.zig");
const numeric = @import("../../numeric.zig");

/// Returns Catalan's constant (`G`) for the given numeric type `N`. This
/// represents the alternating sum of the reciprocals of the odd square numbers
/// (`∑ₙ₌₀^∞ (-1)ⁿ/(2n + 1)² ≈ 0.91596…`).
///
/// ## Arguments
/// * `N` (`comptime type`): The type to generate the `G` value for.
///
/// ## Returns
/// `N`: The `G` value.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `N` must expose the `catalan: N` declaration, or implement the `catalan`
/// method. The expected signature and behavior of `catalan` are as follows:
/// * `fn catalan(anytype) N`: Returns the `G` value.
pub fn catalan(comptime N: type) N {
    comptime if (!meta.isNumeric(N))
        @compileError("zsl.numeric.catalan: " ++ @typeName(N) ++ " is not a numeric type");

    switch (comptime meta.numericType(N)) {
        .bool => @compileError("zsl.numeric.catalan: not defined for " ++ @typeName(N) ++ "."),
        .int => @compileError("zsl.numeric.catalan: not defined for " ++ @typeName(N) ++ "."),
        .float => return 0.91596559417721901505460351493238411077414937428167,
        .dyadic => @compileError("zsl.numeric.catalan: not implemented for " ++ @typeName(N) ++ " yet."),
        .complex => return .{
            .re = numeric.catalan(numeric.Re(N)),
            .im = numeric.cast(numeric.Im(N), 0),
        },
        .custom => {
            if (comptime @hasDecl(N, "catalan") and @TypeOf(N.catalan) == N)
                return N.catalan
            else if (comptime meta.hasMethod(N, "catalan", fn () N, &.{}))
                return N.catalan()
            else
                @compileError("zsl.numeric.catalan: " ++ @typeName(N) ++ " must expose a `catalan: " ++ @typeName(N) ++ "` declaration, or implement `fn catalan() " ++ @typeName(N) ++ "`");
        },
    }
}
