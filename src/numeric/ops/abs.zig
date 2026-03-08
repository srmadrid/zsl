const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Abs(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.abs: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return X,
        .int => return X,
        .rational => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return complex.Abs(X),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlAbs", fn (type) type, &.{X}))
                @compileError("zml.numeric.abs: " ++ @typeName(X) ++ " must implement `fn ZmlAbs(type) type`");

            return X.ZmlAbs(X);
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
/// `X` must implement the required `ZmlAbs` method. The expected signature and
/// behavior of `ZmlAbs` are as follows:
/// * `fn ZmlAbs(type) type`: Returns the type of the absolute value of `x`.
///
/// `numeric.Abs(X)` or `X` must implement the required `zmlAbs` method. The
/// expected signature and behavior of `zmlAbs` are as follows:
/// * `fn zmlAbs(X) numeric.Abs(X)`: Returns the absolute value of `x`.
pub inline fn abs(x: anytype) numeric.Abs(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Abs(X);

    switch (comptime types.numericType(X)) {
        .bool => return x,
        .int => return int.abs(x),
        .rational => return rational.abs(x),
        .float => return float.abs(x),
        .dyadic => return dyadic.abs(x),
        .complex => return complex.abs(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlAbs",
                fn (X) numeric.Abs(X),
                &.{X},
            ) orelse
                @compileError("zml.numeric.abs: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlAbs(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlAbs(x);
        },
    }
}
