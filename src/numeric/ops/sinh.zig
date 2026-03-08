const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Sinh(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.sinh: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => @compileError("zml.numeric.sinh: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zml.numeric.sinh: not defined for " ++ @typeName(X) ++ "."),
        .rational => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlSinh", fn (type) type, &.{X}))
                @compileError("zml.numeric.sinh: " ++ @typeName(X) ++ " must implement `fn ZmlSinh(type) type`");

            return X.ZmlSinh(X);
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
/// `X` must implement the required `ZmlSinh` method. The expected signature and
/// behavior of `ZmlSinh` are as follows:
/// * `fn ZmlSinh(type) type`: Returns the type of the hyperbolic sine of `x`.
///
/// `numeric.Sinh(X)` or `X` must implement the required `zmlSinh` method. The
/// expected signature and behavior of `zmlSinh` are as follows:
/// * `fn zmlSinh(X) numeric.Sinh(X)`: Returns the hyperbolic sine of `x`.
pub inline fn sinh(x: anytype) numeric.Sinh(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Sinh(X);

    switch (comptime types.numericType(X)) {
        .bool => unreachable,
        .int => unreachable,
        .rational => return rational.sinh(x),
        .float => return float.sinh(x),
        .dyadic => return dyadic.sinh(x),
        .complex => return complex.sinh(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlSinh",
                fn (X) numeric.Sinh(X),
                &.{X},
            ) orelse
                @compileError("zml.numeric.sinh: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlSinh(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlSinh(x);
        },
    }
}
