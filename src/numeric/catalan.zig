const complex = @import("../complex.zig");
const dyadic = @import("../dyadic.zig");
const float = @import("../float.zig");
const meta = @import("../meta.zig");

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
        .float => return float.catalan(N),
        .dyadic => return dyadic.catalan(N),
        .complex => return complex.catalan(N), // catalan + 0i
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
