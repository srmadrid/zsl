const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Tan(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.tan: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => @compileError("zml.numeric.tan: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zml.numeric.tan: not defined for " ++ @typeName(X) ++ "."),
        .rational => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlTan", fn (type) type, &.{X}))
                @compileError("zml.numeric.tan: " ++ @typeName(X) ++ " must implement `fn ZmlTan(type) type`");

            return X.ZmlTan(X);
        },
    }
}

/// Returns the tangent `tan(x)` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.tan(x: X) numeric.Tan(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the tangent of.
///
/// ## Returns
/// `numeric.Tan(@TypeOf(x))`: The tangent of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlTan` method. The expected signature and
/// behavior of `ZmlTan` are as follows:
/// * `fn ZmlTan(type) type`: Returns the type of the tangent of `x`.
///
/// `numeric.Tan(X)` or `X` must implement the required `zmlTan` method. The
/// expected signature and behavior of `zmlTan` are as follows:
/// * `fn zmlTan(X) numeric.Tan(X)`: Returns the tangent of `x`.
pub inline fn tan(x: anytype) numeric.Tan(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Tan(X);

    switch (comptime types.numericType(X)) {
        .bool => unreachable,
        .int => unreachable,
        .rational => return rational.tan(x),
        .float => return float.tan(x),
        .dyadic => return dyadic.tan(x),
        .complex => return complex.tan(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlTan",
                fn (X) numeric.Tan(X),
                &.{X},
            ) orelse
                @compileError("zml.numeric.tan: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlTan(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlTan(x);
        },
    }
}
