const types = @import("../../types.zig");

const int = @import("../../int.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Gamma(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zsl.numeric.gamma: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => @compileError("zsl.numeric.gamma: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zsl.numeric.gamma: not defined for " ++ @typeName(X) ++ "."),
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "Gamma", fn (type) type, &.{X}))
                @compileError("zsl.numeric.gamma: " ++ @typeName(X) ++ " must implement `fn Gamma(type) type`");

            return X.Gamma(X);
        },
    }
}

/// Returns the gamma function of a numeric `x`.
///
/// The gamma function is defined as:
/// $$
/// \Gamma(x) = \int_0^\infty t^{x - 1} e^{-t} \mathrm{d}t.
/// $$
///
/// ## Signature
/// ```zig
/// numeric.gamma(x: X) numeric.Gamma(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the gamma function of.
///
/// ## Returns
/// `numeric.Gamma(@TypeOf(x))`: The gamma function  of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `Gamma` method. The expected signature
/// and behavior of `Gamma` are as follows:
/// * `fn Gamma(type) type`: Returns the type of the gamma function of `x`.
///
/// `numeric.Gamma(X)` or `X` must implement the required `gamma` method. The
/// expected signature and behavior of `gamma` are as follows:
/// * `fn gamma(X) numeric.Gamma(X)`: Returns the gamma function of `x`.
pub fn gamma(x: anytype) numeric.Gamma(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Gamma(X);

    switch (comptime types.numericType(X)) {
        .bool => unreachable,
        .int => unreachable,
        .float => return float.gamma(x),
        .dyadic => return dyadic.gamma(x),
        .complex => return complex.gamma(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "gamma",
                fn (X) numeric.Gamma(X),
                &.{X},
            ) orelse
                @compileError("zsl.numeric.gamma: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn gamma(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.gamma(x);
        },
    }
}
