const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Ln(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.ln: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => @compileError("zml.numeric.ln: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zml.numeric.ln: not defined for " ++ @typeName(X) ++ "."),
        .rational => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlLn", fn (type) type, &.{X}))
                @compileError("zml.numeric.ln: " ++ @typeName(X) ++ " must implement `fn ZmlLn(type) type`");

            return X.ZmlLn(X);
        },
    }
}

/// Returns the natural logarithm `logₑ(x)` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.ln(x: X) numeric.Ln(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the natural logarithm of.
///
/// ## Returns
/// `numeric.Ln(@TypeOf(x))`: The natural logarithm of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlLn` method. The expected signature and
/// behavior of `ZmlLn` are as follows:
/// * `fn ZmlLn(type) type`: Returns the type of the natural logarithm of `x`.
///
/// `numeric.Ln(X)` or `X` must implement the required `zmlLn` method. The
/// expected signature and behavior of `zmlLn` are as follows:
/// * `fn zmlLn(X) numeric.Ln(X)`: Returns the natural logarithm of `x`.
pub inline fn ln(x: anytype) numeric.Ln(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Ln(X);

    switch (comptime types.numericType(X)) {
        .bool => unreachable,
        .int => unreachable,
        .rational => return rational.ln(x),
        .float => return float.ln(x),
        .dyadic => return rational.ln(x),
        .complex => return complex.ln(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlLn",
                fn (X) numeric.Ln(X),
                &.{X},
            ) orelse
                @compileError("zml.numeric.ln: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlLn(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlLn(x);
        },
    }
}
