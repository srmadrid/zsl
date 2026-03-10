const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Ln(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zsl.numeric.ln: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => @compileError("zsl.numeric.ln: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zsl.numeric.ln: not defined for " ++ @typeName(X) ++ "."),
        .rational => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "Ln", fn (type) type, &.{X}))
                @compileError("zsl.numeric.ln: " ++ @typeName(X) ++ " must implement `fn Ln(type) type`");

            return X.Ln(X);
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
/// `X` must implement the required `Ln` method. The expected signature and
/// behavior of `Ln` are as follows:
/// * `fn Ln(type) type`: Returns the type of the natural logarithm of `x`.
///
/// `numeric.Ln(X)` or `X` must implement the required `ln` method. The
/// expected signature and behavior of `ln` are as follows:
/// * `fn ln(X) numeric.Ln(X)`: Returns the natural logarithm of `x`.
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
                "ln",
                fn (X) numeric.Ln(X),
                &.{X},
            ) orelse
                @compileError("zsl.numeric.ln: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn ln(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.ln(x);
        },
    }
}
