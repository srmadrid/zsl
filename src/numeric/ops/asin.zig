const types = @import("../../types.zig");

const int = @import("../../int.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Asin(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zsl.numeric.asin: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => @compileError("zsl.numeric.asin: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zsl.numeric.asin: not defined for " ++ @typeName(X) ++ "."),
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "Asin", fn (type) type, &.{X}))
                @compileError("zsl.numeric.asin: " ++ @typeName(X) ++ " must implement `fn Asin(type) type`");

            return X.Asin(X);
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
/// `X` must implement the required `Asin` method. The expected signature and
/// behavior of `Asin` are as follows:
/// * `fn Asin(type) type`: Returns the type of the arcsine of `x`.
///
/// `numeric.Asin(X)` or `X` must implement the required `asin` method. The
/// expected signature and behavior of `asin` are as follows:
/// * `fn asin(X) numeric.Asin(X)`: Returns the arcsine of `x`.
pub fn asin(x: anytype) numeric.Asin(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Asin(X);

    switch (comptime types.numericType(X)) {
        .bool => unreachable,
        .int => unreachable,
        .float => return float.asin(x),
        .dyadic => return dyadic.asin(x),
        .complex => return complex.asin(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "asin",
                fn (X) numeric.Asin(X),
                &.{X},
            ) orelse
                @compileError("zsl.numeric.asin: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn asin(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.asin(x);
        },
    }
}
