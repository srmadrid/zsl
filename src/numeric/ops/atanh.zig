const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Atanh(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.atanh: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => @compileError("zml.numeric.atanh: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zml.numeric.atanh: not defined for " ++ @typeName(X) ++ "."),
        .rational => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlAtanh", fn (type) type, &.{X}))
                @compileError("zml.numeric.atanh: " ++ @typeName(X) ++ " must implement `fn ZmlAtanh(type) type`");

            return X.ZmlAtanh(X);
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
/// `X` must implement the required `ZmlAtanh` method. The expected signature
/// and behavior of `ZmlAtanh` are as follows:
/// * `fn ZmlAtanh(type) type`: Returns the type of the hyperbolic arctangent of
///   `x`.
///
/// `numeric.Atanh(X)` or `X` must implement the required `zmlAtanh` method. The
/// expected signature and behavior of `zmlAtanh` are as follows:
/// * `fn zmlAtanh(X) numeric.Atanh(X)`: Returns the hyperbolic arctangent of `x`.
pub inline fn atanh(x: anytype) numeric.Atanh(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Atanh(X);

    switch (comptime types.numericType(X)) {
        .bool => unreachable,
        .int => unreachable,
        .rational => return rational.atanh(x),
        .float => return float.atanh(x),
        .dyadic => return dyadic.atanh(x),
        .complex => return complex.atanh(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlAtanh",
                fn (X) numeric.Atanh(X),
                &.{X},
            ) orelse
                @compileError("zml.numeric.atanh: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlAtanh(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlAtanh(x);
        },
    }
}
