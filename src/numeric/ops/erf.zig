const meta = @import("../../meta.zig");

const int = @import("../../int.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Erf(X: type) type {
    comptime if (!meta.isNumeric(X))
        @compileError("zsl.numeric.erf: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime meta.numericType(X)) {
        .bool => @compileError("zsl.numeric.erf: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zsl.numeric.erf: not defined for " ++ @typeName(X) ++ "."),
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !meta.hasMethod(X, "Erf", fn (type) type, &.{X}))
                @compileError("zsl.numeric.erf: " ++ @typeName(X) ++ " must implement `fn Erf(type) type`");

            return X.Erf(X);
        },
    }
}

/// Returns the error function of a numeric `x`.
///
/// The error function is defined as:
/// $$
/// \mathrm{erf}(x) = \frac{2}{\sqrt{\pi}} \int_0^x e^{-t^2} \mathrm{d}t.
/// $$
///
/// ## Signature
/// ```zig
/// numeric.erf(x: X) numeric.Erf(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the error function of.
///
/// ## Returns
/// `numeric.Erf(@TypeOf(x))`: The error function of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `Erf` method. The expected signature and
/// behavior of `Erf` are as follows:
/// * `fn Erf(type) type`: Returns the type of the error function of `x`.
///
/// `numeric.Erf(X)` or `X` must implement the required `erf` method. The
/// expected signature and behavior of `erf` are as follows:
/// * `fn erf(X) numeric.Erf(X)`: Returns the error function of `x`.
pub fn erf(x: anytype) numeric.Erf(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Erf(X);

    switch (comptime meta.numericType(X)) {
        .bool => unreachable,
        .int => unreachable,
        .float => return float.erf(x),
        .dyadic => return dyadic.erf(x),
        .complex => return complex.erf(x),
        .custom => {
            const Impl: type = comptime meta.anyHasMethod(
                &.{ R, X },
                "erf",
                fn (X) numeric.Erf(X),
                &.{X},
            ) orelse
                @compileError("zsl.numeric.erf: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn erf(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.erf(x);
        },
    }
}
