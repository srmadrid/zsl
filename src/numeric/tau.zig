const complex = @import("../complex.zig");
const dyadic = @import("../dyadic.zig");
const float = @import("../float.zig");
const meta = @import("../meta.zig");

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
        .float => return float.tau(N),
        .dyadic => return dyadic.tau(N),
        .complex => return complex.tau(N), // tau + 0i
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
