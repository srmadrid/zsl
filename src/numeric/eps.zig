const complex = @import("../complex.zig");
const dyadic = @import("../dyadic.zig");
const float = @import("../float.zig");
const int = @import("../int.zig");
const meta = @import("../meta.zig");

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
        .int => return int.eps(N),
        .float => return float.eps(N),
        .dyadic => return dyadic.eps(N),
        .complex => return complex.eps(N), // ε + 0i
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
