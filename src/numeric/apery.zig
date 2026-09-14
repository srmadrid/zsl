const complex = @import("../complex.zig");
const dyadic = @import("../dyadic.zig");
const float = @import("../float.zig");
const meta = @import("../meta.zig");

/// Returns Apéry's constant (`ζ(3)`) for the given numeric type `N`. This
/// represents the value of the Riemann zeta function evaluated at 3
/// (`∑ₖ₌₁^∞ 1/k³ ≈ 1.202056…`).
///
/// ## Arguments
/// * `N` (`comptime type`): The type to generate the `ζ(3)` value for.
///
/// ## Returns
/// `N`: The `ζ(3)` value.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `N` must expose the `apery: N` declaration, or implement the `apery`
/// method. The expected signature and behavior of `apery` are as follows:
/// * `fn apery(anytype) N`: Returns the `ζ(3)` value.
pub fn apery(comptime N: type) N {
    comptime if (!meta.isNumeric(N))
        @compileError("zsl.numeric.apery: " ++ @typeName(N) ++ " is not a numeric type");

    switch (comptime meta.numericType(N)) {
        .bool => @compileError("zsl.numeric.apery: not defined for " ++ @typeName(N) ++ "."),
        .int => @compileError("zsl.numeric.apery: not defined for " ++ @typeName(N) ++ "."),
        .float => return float.apery(N),
        .dyadic => return dyadic.apery(N),
        .complex => return complex.apery(N), // apery + 0i
        .custom => {
            if (comptime @hasDecl(N, "apery") and @TypeOf(N.apery) == N)
                return N.apery
            else if (comptime meta.hasMethod(N, "apery", fn () N, &.{}))
                return N.apery()
            else
                @compileError("zsl.numeric.apery: " ++ @typeName(N) ++ " must expose a `apery: " ++ @typeName(N) ++ "` declaration, or implement `fn apery() " ++ @typeName(N) ++ "`");
        },
    }
}
