const meta = @import("../../meta.zig");

const int = @import("../../int.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Sin(X: type) type {
    comptime if (!meta.isNumeric(X))
        @compileError("zsl.numeric.sin: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime meta.numericType(X)) {
        .bool => @compileError("zsl.numeric.sin: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zsl.numeric.sin: not defined for " ++ @typeName(X) ++ "."),
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !meta.hasMethod(X, "Sin", fn (type) type, &.{X}))
                @compileError("zsl.numeric.sin: " ++ @typeName(X) ++ " must implement `fn Sin(type) type`");

            return X.Sin(X);
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
/// `X` must implement the required `Sin` method. The expected signature and
/// behavior of `Sin` are as follows:
/// * `fn Sin(type) type`: Returns the type of the sine of `x`.
///
/// `numeric.Sin(X)` or `X` must implement the required `sin` method. The
/// expected signature and behavior of `sin` are as follows:
/// * `fn sin(X) numeric.Sin(X)`: Returns the sine of `x`.
pub fn sin(x: anytype) numeric.Sin(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Sin(X);

    switch (comptime meta.numericType(X)) {
        .bool => unreachable,
        .int => unreachable,
        .float => return float.sin(x),
        .dyadic => return dyadic.sin(x),
        .complex => return complex.sin(x),
        .custom => {
            const Impl: type = comptime meta.anyHasMethod(
                &.{ R, X },
                "sin",
                fn (X) numeric.Sin(X),
                &.{X},
            ) orelse
                @compileError("zsl.numeric.sin: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn sin(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.sin(x);
        },
    }
}
