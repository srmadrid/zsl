const std = @import("std");

const meta = @import("../../meta.zig");
const numeric = @import("../../numeric.zig");

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
        .int => return std.math.maxInt(N),
        .float => return std.math.floatMax(N),
        .dyadic => return .{
            .mantissa = numeric.highest(N.Mantissa),
            .exponent = numeric.highest(N.Exponent) - 1,
            .positive = true,
        },
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
