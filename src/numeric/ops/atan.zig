const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Atan(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.atan: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => @compileError("zml.numeric.atan: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zml.numeric.atan: not defined for " ++ @typeName(X) ++ "."),
        .rational => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlAtan", fn (type) type, &.{X}))
                @compileError("zml.numeric.atan: " ++ @typeName(X) ++ " must implement `fn ZmlAtan(type) type`");

            return X.ZmlAtan(X);
        },
    }
}

/// Returns the arctangent `tan⁻¹(x)` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.atan(x: X) numeric.Atan(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the arctangent of.
///
/// ## Returns
/// `numeric.Atan(@TypeOf(x))`: The arctangent of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlAtan` method. The expected signature and
/// behavior of `ZmlAtan` are as follows:
/// * `fn ZmlAtan(type) type`: Returns the type of the arctangent of `x`.
///
/// `numeric.Atan(X)` or `X` must implement the required `zmlAtan` method. The
/// expected signature and behavior of `zmlAtan` are as follows:
/// * `fn zmlAtan(X) numeric.Atan(X)`: Returns the arctangent of `x`.
pub inline fn atan(x: anytype) numeric.Atan(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Atan(X);

    switch (comptime types.numericType(X)) {
        .bool => unreachable,
        .int => unreachable,
        .rational => return rational.atan(x),
        .float => return float.atan(x),
        .dyadic => return dyadic.atan(x),
        .complex => return complex.atan(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlAtan",
                fn (X) numeric.Atan(X),
                &.{X},
            ) orelse
                @compileError("zml.numeric.atan: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlAtan(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlAtan(x);
        },
    }
}
