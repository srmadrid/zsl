const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Cos(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zsl.numeric.cos: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => @compileError("zsl.numeric.cos: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zsl.numeric.cos: not defined for " ++ @typeName(X) ++ "."),
        .rational => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "Cos", fn (type) type, &.{X}))
                @compileError("zsl.numeric.cos: " ++ @typeName(X) ++ " must implement `fn Cos(type) type`");

            return X.Cos(X);
        },
    }
}

/// Returns the cosine `cos(x)` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.cos(x: X) numeric.Cos(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the cosine of.
///
/// ## Returns
/// `numeric.Cos(@TypeOf(x))`: The cosine of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `Cos` method. The expected signature and
/// behavior of `Cos` are as follows:
/// * `fn Cos(type) type`: Returns the type of the cosine of `x`.
///
/// `numeric.Cos(X)` or `X` must implement the required `cos` method. The
/// expected signature and behavior of `cos` are as follows:
/// * `fn Cos(X) numeric.Cos(X)`: Returns the cosine of `x`.
pub inline fn cos(x: anytype) numeric.Cos(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Cos(X);

    switch (comptime types.numericType(X)) {
        .bool => unreachable,
        .int => unreachable,
        .rational => return rational.cos(x),
        .float => return float.cos(x),
        .dyadic => return dyadic.cos(x),
        .complex => return complex.cos(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "cos",
                fn (X) numeric.Cos(X),
                &.{X},
            ) orelse
                @compileError("zsl.numeric.cos: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn cos(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.cos(x);
        },
    }
}
