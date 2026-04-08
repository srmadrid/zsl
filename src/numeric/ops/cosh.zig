const types = @import("../../types.zig");

const int = @import("../../int.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Cosh(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zsl.numeric.cosh: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => @compileError("zsl.numeric.cosh: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zsl.numeric.cosh: not defined for " ++ @typeName(X) ++ "."),
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "Cosh", fn (type) type, &.{X}))
                @compileError("zsl.numeric.cosh: " ++ @typeName(X) ++ " must implement `fn Cosh(type) type`");

            return X.Cosh(X);
        },
    }
}

/// Returns the hyperbolic cosine `cosh(x)` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.cosh(x: X) numeric.Cosh(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the hyperbolic cosine of.
///
/// ## Returns
/// `numeric.Cosh(@TypeOf(x))`: The hyperbolic cosine of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `Cosh` method. The expected signature and
/// behavior of `Cosh` are as follows:
/// * `fn Cosh(type) type`: Returns the type of the hyperbolic cosine of `x`.
///
/// `numeric.Cosh(X)` or `X` must implement the required `cosh` method. The
/// expected signature and behavior of `cosh` are as follows:
/// * `fn cosh(X) numeric.Cosh(X)`: Returns the hyperbolic cosine of `x`.
pub fn cosh(x: anytype) numeric.Cosh(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Cosh(X);

    switch (comptime types.numericType(X)) {
        .bool => unreachable,
        .int => unreachable,
        .float => return float.cosh(x),
        .dyadic => return dyadic.cosh(x),
        .complex => return complex.cosh(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "cosh",
                fn (X) numeric.Cosh(X),
                &.{X},
            ) orelse
                @compileError("zsl.numeric.cosh: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn cosh(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.cosh(x);
        },
    }
}
