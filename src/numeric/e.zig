const complex = @import("../complex.zig");
const dyadic = @import("../dyadic.zig");
const float = @import("../float.zig");
const meta = @import("../meta.zig");

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
        .float => return float.e(N),
        .dyadic => return dyadic.e(N),
        .complex => return complex.e(N), // e + 0i
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
