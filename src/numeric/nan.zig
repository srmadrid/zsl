const complex = @import("../complex.zig");
const dyadic = @import("../dyadic.zig");
const float = @import("../float.zig");
const meta = @import("../meta.zig");

/// Returns the Not-a-Number (NaN) value for the given numeric type `N`. NaN
/// is used to represent undefined or unrepresentable results in mathematical
/// operations (e.g., 0 ÷ 0).
///
/// ## Arguments
/// * `N` (`comptime type`): The type to generate the NaN value for.
///
/// ## Returns
/// `N`: The Not-a-Number value.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `N` must expose the `nan: N` declaration, or implement the `nan`
/// method. The expected signature and behavior of `nan` are as follows:
/// * `fn nan(anytype) N`: Returns the Not-a-Number value.
pub fn nan(comptime N: type) N {
    comptime if (!meta.isNumeric(N))
        @compileError("zsl.numeric.nan: " ++ @typeName(N) ++ " is not a numeric type");

    switch (comptime meta.numericType(N)) {
        .bool => @compileError("zsl.numeric.nan: not defined for " ++ @typeName(N) ++ "."),
        .int => @compileError("zsl.numeric.nan: not defined for " ++ @typeName(N) ++ "."),
        .float => return float.nan(N),
        .dyadic => return dyadic.nan(N),
        .complex => return complex.nan(N), // nan + nan i
        .custom => {
            if (comptime @hasDecl(N, "nan") and @TypeOf(N.nan) == N)
                return N.nan
            else if (comptime meta.hasMethod(N, "nan", fn () N, &.{}))
                return N.nan()
            else
                @compileError("zsl.numeric.nan: " ++ @typeName(N) ++ " must expose a `nan: " ++ @typeName(N) ++ "` declaration, or implement `fn nan() " ++ @typeName(N) ++ "`");
        },
    }
}
