const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Tanh(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zsl.numeric.tanh: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => @compileError("zsl.numeric.tanh: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zsl.numeric.tanh: not defined for " ++ @typeName(X) ++ "."),
        .rational => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "Tanh", fn (type) type, &.{X}))
                @compileError("zsl.numeric.tanh: " ++ @typeName(X) ++ " must implement `fn Tanh(type) type`");

            return X.Tanh(X);
        },
    }
}

/// Returns the hyperbolic tangent `tanh(x)` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.tanh(x: X) numeric.Tanh(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the hyperbolic tangent of.
///
/// ## Returns
/// `numeric.Tanh(@TypeOf(x))`: The hyperbolic tangent of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `Tanh` method. The expected signature and
/// behavior of `Tanh` are as follows:
/// * `fn Tanh(type) type`: Returns the type of the hyperbolic tangent of `x`.
///
/// `numeric.Tanh(X)` or `X` must implement the required `tanh` method. The
/// expected signature and behavior of `tanh` are as follows:
/// * `fn tanh(X) numeric.Tanh(X)`: Returns the hyperbolic tangent of `x`.
pub inline fn tanh(x: anytype) numeric.Tanh(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Tanh(X);

    switch (comptime types.numericType(X)) {
        .bool => unreachable,
        .int => unreachable,
        .rational => return rational.tanh(x),
        .float => return float.tanh(x),
        .dyadic => return dyadic.tanh(x),
        .complex => return complex.tanh(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "tanh",
                fn (X) numeric.Tanh(X),
                &.{X},
            ) orelse
                @compileError("zsl.numeric.tanh: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn tanh(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.tanh(x);
        },
    }
}
