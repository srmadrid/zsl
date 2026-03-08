const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Tanh(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.tanh: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => @compileError("zml.numeric.tanh: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zml.numeric.tanh: not defined for " ++ @typeName(X) ++ "."),
        .rational => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlTanh", fn (type) type, &.{X}))
                @compileError("zml.numeric.tanh: " ++ @typeName(X) ++ " must implement `fn ZmlTanh(type) type`");

            return X.ZmlTanh(X);
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
/// `X` must implement the required `ZmlTanh` method. The expected signature and
/// behavior of `ZmlTanh` are as follows:
/// * `fn ZmlTanh(type) type`: Returns the type of the hyperbolic tangent of `x`.
///
/// `numeric.Tanh(X)` or `X` must implement the required `zmlTanh` method. The
/// expected signature and behavior of `zmlTanh` are as follows:
/// * `fn zmlTanh(X) numeric.Tanh(X)`: Returns the hyperbolic tangent of `x`.
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
                "zmlTanh",
                fn (X) numeric.Tanh(X),
                &.{X},
            ) orelse
                @compileError("zml.numeric.tanh: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlTanh(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlTanh(x);
        },
    }
}
