const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Acos(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.acos: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => @compileError("zml.numeric.acos: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zml.numeric.acos: not defined for " ++ @typeName(X) ++ "."),
        .rational => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlAcos", fn (type) type, &.{X}))
                @compileError("zml.numeric.acos: " ++ @typeName(X) ++ " must implement `fn ZmlAcos(type) type`");

            return X.ZmlAcos(X);
        },
    }
}

/// Returns the arccosine `cos⁻¹(x)` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.acos(x: X) numeric.Acos(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the arccosine of.
///
/// ## Returns
/// `numeric.Acos(@TypeOf(x))`: The arccosine of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlAcos` method. The expected signature and
/// behavior of `ZmlAcos` are as follows:
/// * `fn ZmlAcos(type) type`: Returns the type of the arccosine of `x`.
///
/// `numeric.Acos(X)` or `X` must implement the required `zmlAcos` method. The
/// expected signature and behavior of `zmlAcos` are as follows:
/// * `fn zmlAcos(X) numeric.Acos(X)`: Returns the arccosine of `x`.
pub inline fn acos(x: anytype) numeric.Acos(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Acos(X);

    switch (comptime types.numericType(X)) {
        .bool => unreachable,
        .int => unreachable,
        .rational => return rational.acos(x),
        .float => return float.acos(x),
        .dyadic => return dyadic.acos(x),
        .complex => return complex.acos(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlAcos",
                fn (X) numeric.Acos(X),
                &.{X},
            ) orelse
                @compileError("zml.numeric.acos: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlAcos(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlAcos(x);
        },
    }
}
