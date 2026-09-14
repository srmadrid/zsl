const complex = @import("../complex.zig");
const dyadic = @import("../dyadic.zig");
const float = @import("../float.zig");
const meta = @import("../meta.zig");

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
        .float => return float.pi(N),
        .dyadic => return dyadic.pi(N),
        .complex => return complex.pi(N), // pi + 0i
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
