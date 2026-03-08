const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Erf(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.erf: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => @compileError("zml.numeric.erf: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zml.numeric.erf: not defined for " ++ @typeName(X) ++ "."),
        .rational => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlErf", fn (type) type, &.{X}))
                @compileError("zml.numeric.erf: " ++ @typeName(X) ++ " must implement `fn ZmlErf(type) type`");

            return X.ZmlErf(X);
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
/// `X` must implement the required `ZmlErf` method. The expected signature and
/// behavior of `ZmlErf` are as follows:
/// * `fn ZmlErf(type) type`: Returns the type of the error function of `x`.
///
/// `numeric.Erf(X)` or `X` must implement the required `zmlErf` method. The
/// expected signature and behavior of `zmlErf` are as follows:
/// * `fn zmlErf(X) numeric.Erf(X)`: Returns the error function of `x`.
pub inline fn erf(x: anytype) numeric.Erf(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Erf(X);

    switch (comptime types.numericType(X)) {
        .bool => unreachable,
        .int => unreachable,
        .rational => return rational.erf(x),
        .float => return float.erf(x),
        .dyadic => return dyadic.erf(x),
        .complex => return complex.erf(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlErf",
                fn (X) numeric.Erf(X),
                &.{X},
            ) orelse
                @compileError("zml.numeric.erf: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlErf(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlErf(x);
        },
    }
}
