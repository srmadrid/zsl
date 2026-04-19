const meta = @import("../../meta.zig");

const int = @import("../../int.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Acos(X: type) type {
    comptime if (!meta.isNumeric(X))
        @compileError("zsl.numeric.acos: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime meta.numericType(X)) {
        .bool => @compileError("zsl.numeric.acos: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zsl.numeric.acos: not defined for " ++ @typeName(X) ++ "."),
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !meta.hasMethod(X, "Acos", fn (type) type, &.{X}))
                @compileError("zsl.numeric.acos: " ++ @typeName(X) ++ " must implement `fn Acos(type) type`");

            return X.Acos(X);
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
/// `X` must implement the required `Acos` method. The expected signature and
/// behavior of `Acos` are as follows:
/// * `fn Acos(type) type`: Returns the type of the arccosine of `x`.
///
/// `numeric.Acos(X)` or `X` must implement the required `acos` method. The
/// expected signature and behavior of `acos` are as follows:
/// * `fn acos(X) numeric.Acos(X)`: Returns the arccosine of `x`.
pub fn acos(x: anytype) numeric.Acos(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Acos(X);

    switch (comptime meta.numericType(X)) {
        .bool => unreachable,
        .int => unreachable,
        .float => return float.acos(x),
        .dyadic => return dyadic.acos(x),
        .complex => return complex.acos(x),
        .custom => {
            const Impl: type = comptime meta.anyHasMethod(
                &.{ R, X },
                "acos",
                fn (X) numeric.Acos(X),
                &.{X},
            ) orelse
                @compileError("zsl.numeric.acos: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn acos(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.acos(x);
        },
    }
}
