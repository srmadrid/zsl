const dyadic = @import("../dyadic.zig");
const float = @import("../float.zig");
const meta = @import("../meta.zig");

/// Returns positive infinity (`∞`) for the given numeric type `N`.
///
/// ## Arguments
/// * `N` (`comptime type`): The type to generate the infinity value for.
///
/// ## Returns
/// `N`: The positive infinity value.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `N` must expose the `inf: N` declaration, or implement the `inf`
/// method. The expected signature and behavior of `inf` are as follows:
/// * `fn inf(anytype) N`: Returns the positive infinity value.
pub fn inf(comptime N: type) N {
    comptime if (!meta.isNumeric(N))
        @compileError("zsl.numeric.inf: " ++ @typeName(N) ++ " is not a numeric type");

    switch (comptime meta.numericType(N)) {
        .bool => @compileError("zsl.numeric.inf: not defined for " ++ @typeName(N) ++ "."),
        .int => @compileError("zsl.numeric.inf: not defined for " ++ @typeName(N) ++ "."),
        .float => return float.inf(N),
        .dyadic => return dyadic.inf(N),
        .complex => @compileError("zsl.numeric.inf: not defined for " ++ @typeName(N) ++ "."),
        .custom => {
            if (comptime @hasDecl(N, "inf") and @TypeOf(N.inf) == N)
                return N.inf
            else if (comptime meta.hasMethod(N, "inf", fn () N, &.{}))
                return N.inf()
            else
                @compileError("zsl.numeric.inf: " ++ @typeName(N) ++ " must expose a `inf: " ++ @typeName(N) ++ "` declaration, or implement `fn inf() " ++ @typeName(N) ++ "`");
        },
    }
}
