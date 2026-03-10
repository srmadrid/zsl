const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Abs2(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zsl.numeric.abs2: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return X,
        .int => return X,
        .rational => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return complex.Abs2(X),
        .custom => {
            if (comptime !types.hasMethod(X, "Abs2", fn (type) type, &.{X}))
                @compileError("zsl.numeric.abs2: " ++ @typeName(X) ++ " must implement `fn Abs2(type) type`");

            return X.Abs2(X);
        },
    }
}

/// Returns the squared absolute value of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.abs2(x: X) numeric.Abs2(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the squared absolute value of.
///
/// ## Returns
/// `numeric.Abs2(@TypeOf(x))`: The squared absolute value of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `Abs2` method. The expected signature and
/// behavior of `Abs2` are as follows:
/// * `fn Abs2(type) type`: Returns the type of the squared absolute value of
///   `x`.
///
/// `numeric.Abs2(X)` or `X` must implement the required `abs2` method. The
/// expected signature and behavior of `abs2` are as follows:
/// * `fn abs2(X) numeric.Abs2(X)`: Returns the squared absolute value of
///   `x`.
pub inline fn abs2(x: anytype) numeric.Abs2(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Abs2(X);

    switch (comptime types.numericType(X)) {
        .bool => return x,
        .int => return int.mul(x, x),
        .rational => return rational.mul(x, x),
        .float => return float.mul(x, x),
        .dyadic => return dyadic.mul(x, x),
        .complex => return complex.abs2(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "abs2",
                fn (X) numeric.Abs2(X),
                &.{X},
            ) orelse
                @compileError("zsl.numeric.abs2: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn abs2(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.abs2(x);
        },
    }
}
