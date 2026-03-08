const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Exp(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.exp: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => @compileError("zml.numeric.exp: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zml.numeric.exp: not defined for " ++ @typeName(X) ++ "."),
        .rational => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlExp", fn (type) type, &.{X}))
                @compileError("zml.numeric.exp: " ++ @typeName(X) ++ " must implement `fn ZmlExp(type) type`");

            return X.ZmlExp(X);
        },
    }
}

/// Returns the exponential `eˣ` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.exp(x: X) numeric.Exp(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the exponential of.
///
/// ## Returns
/// `numeric.Exp(@TypeOf(x))`: The exponential of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlExp` method. The expected signature and
/// behavior of `ZmlExp` are as follows:
/// * `fn ZmlExp(type) type`: Returns the type of the exponential of `x`.
///
/// `numeric.Exp(X)` or `X` must implement the required `zmlExp` method. The
/// expected signature and behavior of `zmlExp` are as follows:
/// * `fn zmlExp(X) numeric.Exp(X)`: Returns the exponential of `x`.
pub inline fn exp(x: anytype) numeric.Exp(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Exp(X);

    switch (comptime types.numericType(X)) {
        .bool => unreachable,
        .int => unreachable,
        .rational => return rational.exp(x),
        .float => return float.exp(x),
        .dyadic => return dyadic.exp(x),
        .complex => return complex.exp(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlExp",
                fn (X) numeric.Exp(X),
                &.{X},
            ) orelse
                @compileError("zml.numeric.exp: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlExp(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlExp(x);
        },
    }
}
