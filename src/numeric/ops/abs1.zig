const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Abs1(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.abs1: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return X,
        .int => return X,
        .rational => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return complex.Abs1(X),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlAbs1", fn (type) type, &.{X}))
                @compileError("zml.numeric.abs1: " ++ @typeName(X) ++ " must implement `fn ZmlAbs1(type) type`");

            return X.ZmlAbs1(X);
        },
    }
}

/// Returns the 1-norm of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.abs1(x: X) numeric.Abs1(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the 1-norm of.
///
/// ## Returns
/// `numeric.Abs1(@TypeOf(x))`: The 1-norm of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlAbs1` method. The expected signature and
/// behavior of `ZmlAbs1` are as follows:
/// * `fn ZmlAbs1(type) type`: Returns the type of the 1-norm of `x`.
///
/// `numeric.Abs1(X)` or `X` must implement the required `zmlAbs1` method. The
/// expected signature and behavior of `zmlAbs1` are as follows:
/// * `fn zmlAbs1(X) numeric.Abs1(X)`: Returns the 1-norm of `x`.
pub inline fn abs1(x: anytype) numeric.Abs1(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Abs1(X);

    switch (comptime types.numericType(X)) {
        .bool => return x,
        .int => return int.abs(x),
        .rational => return rational.abs(x),
        .float => return float.abs(x),
        .dyadic => return dyadic.abs(x),
        .complex => return complex.abs1(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlAbs1",
                fn (X) numeric.Abs1(X),
                &.{X},
            ) orelse
                @compileError("zml.numeric.abs1: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlAbs1(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlAbs1(x);
        },
    }
}
