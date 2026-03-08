const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Sqrt(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.sqrt: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => @compileError("zml.numeric.sqrt: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zml.numeric.sqrt: not defined for " ++ @typeName(X) ++ "."),
        .rational => return X,
        .float => return X,
        .dyadic => return X,
        .cfloat => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlSqrt", fn (type) type, &.{X}))
                @compileError("zml.numeric.sqrt: " ++ @typeName(X) ++ " must implement `fn ZmlSqrt(type) type`");

            return X.ZmlSqrt(X);
        },
    }
}

/// Returns the square root `√x` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.sqrt(x: X) numeric.Sqrt(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the square root of.
///
/// ## Returns
/// `numeric.Sqrt(@TypeOf(x))`: The square root of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlSqrt` method. The expected signature and
/// behavior of `ZmlSqrt` are as follows:
/// * `fn ZmlSqrt(type) type`: Returns the type of the square root of `x`.
///
/// `numeric.Sqrt(X)` or `X` must implement the required `zmlSqrt` method. The
/// expected signature and behavior of `zmlSqrt` are as follows:
/// * `fn zmlSqrt(X) numeric.Sqrt(X)`: Returns the square root of `x`.
pub inline fn sqrt(x: anytype) numeric.Sqrt(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Sqrt(X);

    switch (comptime types.numericType(X)) {
        .bool => unreachable,
        .int => unreachable,
        .rational => return rational.sqrt(x),
        .float => return float.sqrt(x),
        .dyadic => return dyadic.sqrt(x),
        .complex => return complex.sqrt(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlSqrt",
                fn (X) numeric.Sqrt(X),
                &.{X},
            ) orelse
                @compileError("zml.numeric.sqrt: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlSqrt(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlSqrt(x);
        },
    }
}
