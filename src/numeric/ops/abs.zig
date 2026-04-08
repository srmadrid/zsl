const types = @import("../../types.zig");

const int = @import("../../int.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Abs(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zsl.numeric.abs: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return X,
        .int => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return complex.Abs(X),
        .custom => {
            if (comptime !types.hasMethod(X, "Abs", fn (type) type, &.{X}))
                @compileError("zsl.numeric.abs: " ++ @typeName(X) ++ " must implement `fn Abs(type) type`");

            return X.Abs(X);
        },
    }
}

/// Returns the absolute value of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.abs(x: X) numeric.Abs(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the absolute value of.
///
/// ## Returns
/// `numeric.Abs(@TypeOf(x))`: The absolute value of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `abs` method. The expected signature and
/// behavior of `abs` are as follows:
/// * `fn abs(type) type`: Returns the type of the absolute value of `x`.
///
/// `numeric.Abs(X)` or `X` must implement the required `abs` method. The
/// expected signature and behavior of `abs` are as follows:
/// * `fn abs(X) numeric.Abs(X)`: Returns the absolute value of `x`.
pub fn abs(x: anytype) numeric.Abs(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Abs(X);

    switch (comptime types.numericType(X)) {
        .bool => return x,
        .int => return int.abs(x),
        .float => return float.abs(x),
        .dyadic => return dyadic.abs(x),
        .complex => return complex.abs(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "abs",
                fn (X) numeric.Abs(X),
                &.{X},
            ) orelse
                @compileError("zsl.numeric.abs: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn abs(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.abs(x);
        },
    }
}
