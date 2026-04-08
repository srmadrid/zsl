const types = @import("../../types.zig");

const int = @import("../../int.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Atanh(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zsl.numeric.atanh: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => @compileError("zsl.numeric.atanh: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zsl.numeric.atanh: not defined for " ++ @typeName(X) ++ "."),
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "Atanh", fn (type) type, &.{X}))
                @compileError("zsl.numeric.atanh: " ++ @typeName(X) ++ " must implement `fn Atanh(type) type`");

            return X.Atanh(X);
        },
    }
}

/// Returns the hyperbolic arctangent `tanh⁻¹(x)` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.atanh(x: X) numeric.Atanh(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the hyperbolic arctangent of.
///
/// ## Returns
/// `numeric.Atanh(@TypeOf(x))`: The hyperbolic arctangent of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `Atanh` method. The expected signature
/// and behavior of `Atanh` are as follows:
/// * `fn Atanh(type) type`: Returns the type of the hyperbolic arctangent of
///   `x`.
///
/// `numeric.Atanh(X)` or `X` must implement the required `atanh` method. The
/// expected signature and behavior of `atanh` are as follows:
/// * `fn atanh(X) numeric.Atanh(X)`: Returns the hyperbolic arctangent of `x`.
pub fn atanh(x: anytype) numeric.Atanh(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Atanh(X);

    switch (comptime types.numericType(X)) {
        .bool => unreachable,
        .int => unreachable,
        .float => return float.atanh(x),
        .dyadic => return dyadic.atanh(x),
        .complex => return complex.atanh(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "atanh",
                fn (X) numeric.Atanh(X),
                &.{X},
            ) orelse
                @compileError("zsl.numeric.atanh: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn atanh(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.atanh(x);
        },
    }
}
