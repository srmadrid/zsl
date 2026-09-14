const complex = @import("../complex.zig");
const dyadic = @import("../dyadic.zig");
const float = @import("../float.zig");
const meta = @import("../meta.zig");

/// Returns the golden ratio (`φ`) for the given numeric type `N`. This
/// represents the positive solution to the equation `x² - x - 1 = 0`
/// (`(1 + √5) / 2 ≈ 1.61803…`).
///
/// ## Arguments
/// * `N` (`comptime type`): The type to generate the `φ` value for.
///
/// ## Returns
/// `N`: The `φ` value.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `N` must expose the `phi: N` declaration, or implement the `phi`
/// method. The expected signature and behavior of `phi` are as follows:
/// * `fn phi(anytype) N`: Returns the `φ` value.
pub fn phi(comptime N: type) N {
    comptime if (!meta.isNumeric(N))
        @compileError("zsl.numeric.phi: " ++ @typeName(N) ++ " is not a numeric type");

    switch (comptime meta.numericType(N)) {
        .bool => @compileError("zsl.numeric.phi: not defined for " ++ @typeName(N) ++ "."),
        .int => @compileError("zsl.numeric.phi: not defined for " ++ @typeName(N) ++ "."),
        .float => return float.phi(N),
        .dyadic => return dyadic.phi(N),
        .complex => return complex.phi(N), // phi + 0i
        .custom => {
            if (comptime @hasDecl(N, "phi") and @TypeOf(N.phi) == N)
                return N.phi
            else if (comptime meta.hasMethod(N, "phi", fn () N, &.{}))
                return N.phi()
            else
                @compileError("zsl.numeric.phi: " ++ @typeName(N) ++ " must expose a `phi: " ++ @typeName(N) ++ "` declaration, or implement `fn phi() " ++ @typeName(N) ++ "`");
        },
    }
}
