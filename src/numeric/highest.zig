const dyadic = @import("../dyadic.zig");
const float = @import("../float.zig");
const int = @import("../int.zig");
const meta = @import("../meta.zig");

/// Returns the maximum representable finite value (highest point on the number
/// line) for the given numeric type `N`.
///
/// ## Arguments
/// * `N` (`comptime type`): The type to generate the highest value for.
///
/// ## Returns
/// `N`: The maximum representable value.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `N` must expose the `highest: N` declaration, or implement the `highest`
/// method. The expected signature and behavior of `highest` are as follows:
/// * `fn highest(anytype) N`: Returns the highest representable value.
pub fn highest(comptime N: type) N {
    comptime if (!meta.isNumeric(N))
        @compileError("zsl.numeric.highest: " ++ @typeName(N) ++ " is not a numeric type");

    switch (comptime meta.numericType(N)) {
        .bool => return true,
        .int => return int.highest(N),
        .float => return float.highest(N),
        .dyadic => return dyadic.highest(N),
        .complex => @compileError("zsl.numeric.highest: not defined for " ++ @typeName(N) ++ "."),
        .custom => {
            if (comptime @hasDecl(N, "highest") and @TypeOf(N.highest) == N)
                return N.highest
            else if (comptime meta.hasMethod(N, "highest", fn () N, &.{}))
                return N.highest()
            else
                @compileError("zsl.numeric.highest: " ++ @typeName(N) ++ " must expose a `highest: " ++ @typeName(N) ++ "` declaration, or implement `fn highest() " ++ @typeName(N) ++ "`");
        },
    }
}
