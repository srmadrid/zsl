const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Re(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.re: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return X,
        .int => return X,
        .rational => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return types.Scalar(X),
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlRe", fn (type) type, &.{X}))
                @compileError("zml.numeric.re: " ++ @typeName(X) ++ " must implement `fn ZmlRe(type) type`");

            return X.ZmlRe(X);
        },
    }
}

/// Returns the real part of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.re(x: X) numeric.Re(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the real part of.
///
/// ## Returns
/// `numeric.Re(@TypeOf(x))`: The real part of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlRe` method. The expected signature and
/// behavior of `ZmlRe` are as follows:
/// * `fn ZmlRe(type) type`: Returns the type of the real part of `x`.
///
/// `numeric.Re(X)` or `X` must implement the required `zmlRe` method. The
/// expected signature and behavior of `zmlRe` are as follows:
/// * `fn zmlRe(X) numeric.Re(X)`: Returns the real part of `x`.
pub inline fn re(x: anytype) numeric.Re(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Re(X);

    switch (comptime types.numericType(X)) {
        .bool => return x,
        .int => return x,
        .rational => return x,
        .float => return x,
        .dyadic => return x,
        .complex => return x.re,
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlRe",
                fn (X) numeric.Re(X),
                &.{X},
            ) orelse
                @compileError("zml.numeric.re: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlRe(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlRe(x);
        },
    }
}
