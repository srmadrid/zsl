const dyadic = @import("../dyadic.zig");
const float = @import("../float.zig");
const int = @import("../int.zig");
const meta = @import("../meta.zig");

/// Returns the minimum representable finite value (lowest point on the number
/// line) for the given numeric type `N`.
///
/// ## Arguments
/// * `N` (`comptime type`): The type to generate the lowest value for.
///
/// ## Returns
/// `N`: The minimum representable value.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `N` must expose the `lowest: N` declaration, or implement the `lowest`
/// method. The expected signature and behavior of `lowest` are as follows:
/// * `fn lowest(anytype) N`: Returns the lowest representable value.
pub fn lowest(comptime N: type) N {
    comptime if (!meta.isNumeric(N))
        @compileError("zsl.numeric.lowest: " ++ @typeName(N) ++ " is not a numeric type");

    switch (comptime meta.numericType(N)) {
        .bool => return true,
        .int => return int.lowest(N),
        .float => return float.lowest(N),
        .dyadic => return dyadic.lowest(N),
        .complex => @compileError("zsl.numeric.lowest: not defined for " ++ @typeName(N) ++ "."),
        .custom => {
            if (comptime @hasDecl(N, "lowest") and @TypeOf(N.lowest) == N)
                return N.lowest
            else if (comptime meta.hasMethod(N, "lowest", fn () N, &.{}))
                return N.lowest()
            else
                @compileError("zsl.numeric.lowest: " ++ @typeName(N) ++ " must expose a `lowest: " ++ @typeName(N) ++ "` declaration, or implement `fn lowest() " ++ @typeName(N) ++ "`");
        },
    }
}
