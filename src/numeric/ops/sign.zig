const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Sign(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.sign: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return X,
        .int => return X,
        .rational => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlSign", fn (type) type, &.{X}))
                @compileError("zml.numeric.sign: " ++ @typeName(X) ++ " must implement `fn ZmlSign(type) type`");

            return X.ZmlSign(X);
        },
    }
}

/// Returns the sign of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.sign(x: X) numeric.Sign(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the sign of.
///
/// ## Returns
/// `numeric.Sign(@TypeOf(x))`: The sign of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlSign` method. The expected signature and
/// behavior of `ZmlSign` are as follows:
/// * `fn ZmlSign(type) type`: Returns the type of the sign of `x`.
///
/// `numeric.Sign(X)` or `X` must implement the required `zmlSign` method. The
/// expected signature and behavior of `zmlSign` are as follows:
/// * `fn zmlSign(X) numeric.Sign(X)`: Returns the sign of `x`.
pub inline fn sign(x: anytype) numeric.Sign(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Sign(X);

    switch (comptime types.numericType(X)) {
        .bool => return x,
        .int => return int.sign(x),
        .rational => return rational.sign(x),
        .float => return float.sign(x),
        .dyadic => return dyadic.sign(x),
        .complex => return complex.sign(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlSign",
                fn (X) numeric.Sign(X),
                &.{X},
            ) orelse
                @compileError("zml.numeric.sign: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlSign(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlSign(x);
        },
    }
}
