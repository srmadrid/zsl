const std = @import("std");

const meta = @import("../../meta.zig");
const numeric = @import("../../numeric.zig");

/// Returns the machine epsilon (`ε`) for the given numeric type `N`. This
/// represents the upper bound on the relative approximation error due to
/// rounding, typically defined as the difference between `1` and the next
/// representable value (i.e., the smallest positive value `ε > 0` such that
/// `1 + ε ≠ 1`).
///
/// ## Arguments
/// * `N` (`comptime type`): The type to generate the machine epsilon for.
///
/// ## Returns
/// `N`: The machine epsilon (`ε`).
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `N` must expose the `eps: N` declaration, or implement the `eps`
/// method. The expected signature and behavior of `eps` are as follows:
/// * `fn eps(anytype) N`: Returns the machine epsilon value.
pub fn eps(comptime N: type) N {
    comptime if (!meta.isNumeric(N))
        @compileError("zsl.numeric.eps: " ++ @typeName(N) ++ " is not a numeric type");

    switch (comptime meta.numericType(N)) {
        .bool => return false,
        .int => return 0,
        .float => return std.math.floatEps(N),
        .dyadic => return .{
            .mantissa = 1 << (@typeInfo(N.Mantissa).int.bits - 1),
            .exponent = -numeric.cast(N.Exponent, 2 * (@typeInfo(N.Mantissa).int.bits - 1)),
            .positive = true,
        },
        .complex => return .{
            .re = numeric.eps(numeric.Re(N)),
            .im = numeric.cast(numeric.Im(N), 0),
        },
        .custom => {
            if (comptime @hasDecl(N, "eps") and @TypeOf(N.eps) == N)
                return N.eps
            else if (comptime meta.hasMethod(N, "eps", fn () N, &.{}))
                return N.eps()
            else
                @compileError("zsl.numeric.eps: " ++ @typeName(N) ++ " must expose a `eps: " ++ @typeName(N) ++ "` declaration, or implement `fn eps() " ++ @typeName(N) ++ "`");
        },
    }
}
