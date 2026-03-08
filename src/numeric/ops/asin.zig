const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Asin(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.asin: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => @compileError("zml.numeric.asin: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zml.numeric.asin: not defined for " ++ @typeName(X) ++ "."),
        .rational => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlAsin", fn (type) type, &.{X}))
                @compileError("zml.numeric.asin: " ++ @typeName(X) ++ " must implement `fn ZmlAsin(type) type`");

            return X.ZmlAsin(X);
        },
    }
}

/// Returns the arcsine `sin⁻¹(x)` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.asin(x: X) numeric.Asin(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the arcsine of.
///
/// ## Returns
/// `numeric.Asin(@TypeOf(x))`: The arcsine of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlAsin` method. The expected signature and
/// behavior of `ZmlAsin` are as follows:
/// * `fn ZmlAsin(type) type`: Returns the type of the arcsine of `x`.
///
/// `numeric.Asin(X)` or `X` must implement the required `zmlAsin` method. The
/// expected signature and behavior of `zmlAsin` are as follows:
/// * `fn zmlAsin(X) numeric.Asin(X)`: Returns the arcsine of `x`.
pub inline fn asin(x: anytype) numeric.Asin(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Asin(X);

    switch (comptime types.numericType(X)) {
        .bool => unreachable,
        .int => unreachable,
        .rational => return rational.asin(x),
        .float => return float.asin(x),
        .dyadic => return dyadic.asin(x),
        .complex => return complex.asin(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlAsin",
                fn (X) numeric.Asin(X),
                &.{X},
            ) orelse
                @compileError("zml.numeric.asin: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlAsin(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlAsin(x);
        },
    }
}
