const types = @import("../../types.zig");

const int = @import("../../int.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Cbrt(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zsl.numeric.cbrt: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => @compileError("zsl.numeric.cbrt: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zsl.numeric.cbrt: not defined for " ++ @typeName(X) ++ "."),
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "Cbrt", fn (type) type, &.{X}))
                @compileError("zsl.numeric.cbrt: " ++ @typeName(X) ++ " must implement `fn Cbrt(type) type`");

            return X.Cbrt(X);
        },
    }
}

/// Returns the cube root `∛x` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.cbrt(x: X) numeric.Cbrt(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the cube root of.
///
/// ## Returns
/// `numeric.Cbrt(@TypeOf(x))`: The cube root of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `Cbrt` method. The expected signature and
/// behavior of `Cbrt` are as follows:
/// * `fn Cbrt(type) type`: Returns the type of the cube root of `x`.
///
/// `numeric.Cbrt(X)` or `X` must implement the required `cbrt` method. The
/// expected signature and behavior of `cbrt` are as follows:
/// * `fn cbrt(X) numeric.Cbrt(X)`: Returns the cube root of `x`.
pub fn cbrt(x: anytype) numeric.Cbrt(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Cbrt(X);

    switch (comptime types.numericType(X)) {
        .bool => unreachable,
        .int => unreachable,
        .float => return float.cbrt(x),
        .dyadic => return dyadic.cbrt(x),
        .complex => return complex.cbrt(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "cbrt",
                fn (X) numeric.Cbrt(X),
                &.{X},
            ) orelse
                @compileError("zsl.numeric.cbrt: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn cbrt(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.cbrt(x);
        },
    }
}
