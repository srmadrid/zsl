const types = @import("../../types.zig");

const int = @import("../../int.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Sinh(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zsl.numeric.sinh: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => @compileError("zsl.numeric.sinh: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zsl.numeric.sinh: not defined for " ++ @typeName(X) ++ "."),
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "Sinh", fn (type) type, &.{X}))
                @compileError("zsl.numeric.sinh: " ++ @typeName(X) ++ " must implement `fn Sinh(type) type`");

            return X.Sinh(X);
        },
    }
}

/// Returns the hyperbolic sine `sinh(x)` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.sinh(x: X) numeric.Sinh(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the hyperbolic sine of.
///
/// ## Returns
/// `numeric.Sinh(@TypeOf(x))`: The hyperbolic sine of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `Sinh` method. The expected signature and
/// behavior of `Sinh` are as follows:
/// * `fn Sinh(type) type`: Returns the type of the hyperbolic sine of `x`.
///
/// `numeric.Sinh(X)` or `X` must implement the required `sinh` method. The
/// expected signature and behavior of `sinh` are as follows:
/// * `fn sinh(X) numeric.Sinh(X)`: Returns the hyperbolic sine of `x`.
pub fn sinh(x: anytype) numeric.Sinh(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Sinh(X);

    switch (comptime types.numericType(X)) {
        .bool => unreachable,
        .int => unreachable,
        .float => return float.sinh(x),
        .dyadic => return dyadic.sinh(x),
        .complex => return complex.sinh(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "sinh",
                fn (X) numeric.Sinh(X),
                &.{X},
            ) orelse
                @compileError("zsl.numeric.sinh: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn sinh(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.sinh(x);
        },
    }
}
