const dyadic = @import("../dyadic.zig");
const float = @import("../float.zig");
const int = @import("../int.zig");
const meta = @import("../meta.zig");

/// Returns the smallest positive magnitude strictly greater than zero (closest
/// to zero) for the given numeric type `N`.
///
/// ## Arguments
/// * `N` (`comptime type`): The type to generate the smallest positive value
///   for.
///
/// ## Returns
/// `N`: The smallest positive non-zero magnitude.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `N` must expose the `smallest: N` declaration, or implement the `smallest`
/// method. The expected signature and behavior of `smallest` are as follows:
/// * `fn smallest(anytype) N`: Returns the smallest positive non-zero magnitude.
pub fn smallest(comptime N: type) N {
    comptime if (!meta.isNumeric(N))
        @compileError("zsl.numeric.smallest: " ++ @typeName(N) ++ " is not a numeric type");

    switch (comptime meta.numericType(N)) {
        .bool => return true,
        .int => return int.smallest(N),
        .float => return float.smallest(N),
        .dyadic => return dyadic.smallest(N),
        .complex => @compileError("zsl.numeric.smallest: not defined for " ++ @typeName(N) ++ "."),
        .custom => {
            if (comptime @hasDecl(N, "smallest") and @TypeOf(N.smallest) == N)
                return N.smallest
            else if (comptime meta.hasMethod(N, "smallest", fn () N, &.{}))
                return N.smallest()
            else
                @compileError("zsl.numeric.smallest: " ++ @typeName(N) ++ " must expose a `smallest: " ++ @typeName(N) ++ "` declaration, or implement `fn smallest() " ++ @typeName(N) ++ "`");
        },
    }
}
