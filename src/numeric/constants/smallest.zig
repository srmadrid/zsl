const std = @import("std");

const meta = @import("../../meta.zig");
const numeric = @import("../../numeric.zig");

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
        .int => return 1,
        .float => return std.math.floatMin(N),
        .dyadic => return .{
            .mantissa = 1 << (@typeInfo(N.Mantissa).int.bits - 1),
            .exponent = numeric.lowest(N.Exponent),
            .positive = true,
        },
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
