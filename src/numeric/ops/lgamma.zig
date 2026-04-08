const types = @import("../../types.zig");

const int = @import("../../int.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Lgamma(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zsl.numeric.lgamma: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => @compileError("zsl.numeric.lgamma: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zsl.numeric.lgamma: not defined for " ++ @typeName(X) ++ "."),
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "Lgamma", fn (type) type, &.{X}))
                @compileError("zsl.numeric.lgamma: " ++ @typeName(X) ++ " must implement `fn Lgamma(type) type`");

            return X.Lgamma(X);
        },
    }
}

/// Returns the log-gamma function of a numeric `x`.
///
/// The log-gamma function is defined as:
/// $$
/// \log(\Gamma(x)) = \left(\int_0^\infty t^{x - 1} e^{-t} \mathrm{d}t\right).
/// $$
///
/// ## Signature
/// ```zig
/// numeric.lgamma(x: X) numeric.Lgamma(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the log-gamma function of.
///
/// ## Returns
/// `numeric.Lgamma(@TypeOf(x))`: The log-gamma function  of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `Lgamma` method. The expected signature
/// and behavior of `Lgamma` are as follows:
/// * `fn Lgamma(type) type`: Returns the type of the log-gamma function of
///   `x`.
///
/// `numeric.Lgamma(X)` or `X` must implement the required `lgamma` method.
/// The expected signature and behavior of `lgamma` are as follows:
/// * `fn lgamma(X) numeric.Lgamma(X)`: Returns the log-gamma function of `x`.
pub fn lgamma(x: anytype) numeric.Lgamma(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Lgamma(X);

    switch (comptime types.numericType(X)) {
        .bool => unreachable,
        .int => unreachable,
        .float => return float.lgamma(x),
        .dyadic => return dyadic.lgamma(x),
        .complex => return complex.lgamma(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "lgamma",
                fn (X) numeric.Lgamma(X),
                &.{X},
            ) orelse
                @compileError("zsl.numeric.lgamma: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn lgamma(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.lgamma(x);
        },
    }
}
