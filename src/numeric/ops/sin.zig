const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Sin(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.sin: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => @compileError("zml.numeric.sin: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zml.numeric.sin: not defined for " ++ @typeName(X) ++ "."),
        .rational => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlSin", fn (type) type, &.{X}))
                @compileError("zml.numeric.sin: " ++ @typeName(X) ++ " must implement `fn ZmlSin(type) type`");

            return X.ZmlSin(X);
        },
    }
}

/// Returns the sine `sin(x)` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.sin(x: X) numeric.Sin(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the sine of.
///
/// ## Returns
/// `numeric.Sin(@TypeOf(x))`: The sine of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlSin` method. The expected signature and
/// behavior of `ZmlSin` are as follows:
/// * `fn ZmlSin(type) type`: Returns the type of the sine of `x`.
///
/// `numeric.Sin(X)` or `X` must implement the required `zmlSin` method. The
/// expected signature and behavior of `zmlSin` are as follows:
/// * `fn zmlSin(X) numeric.Sin(X)`: Returns the sine of `x`.
pub inline fn sin(x: anytype) numeric.Sin(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Sin(X);

    switch (comptime types.numericType(X)) {
        .bool => unreachable,
        .int => unreachable,
        .rational => return rational.sin(x),
        .float => return float.sin(x),
        .dyadic => return dyadic.sin(x),
        .complex => return complex.sin(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlSin",
                fn (X) numeric.Sin(X),
                &.{X},
            ) orelse
                @compileError("zml.numeric.sin: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlSin(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlSin(x);
        },
    }
}
