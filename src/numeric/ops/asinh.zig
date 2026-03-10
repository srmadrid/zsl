const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Asinh(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zsl.numeric.asinh: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => @compileError("zsl.numeric.asinh: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zsl.numeric.asinh: not defined for " ++ @typeName(X) ++ "."),
        .rational => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "Asinh", fn (type) type, &.{X}))
                @compileError("zsl.numeric.asinh: " ++ @typeName(X) ++ " must implement `fn Asinh(type) type`");

            return X.Asinh(X);
        },
    }
}

/// Returns the hyperbolic arcsine `sinh⁻¹(x)` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.asinh(x: X) numeric.Asinh(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the hyperbolic arcsine of.
///
/// ## Returns
/// `numeric.Asinh(@TypeOf(x))`: The hyperbolic arcsine of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `Asinh` method. The expected signature and
/// behavior of `Asinh` are as follows:
/// * `fn Asinh(type) type`: Returns the type of the hyperbolic arcsine of
///   `x`.
///
/// `numeric.Asinh(X)` or `X` must implement the required `asinh` method. The
/// expected signature and behavior of `asinh` are as follows:
/// * `fn asinh(X) numeric.Asinh(X)`: Returns the hyperbolic arcsine of `x`.
pub inline fn asinh(x: anytype) numeric.Asinh(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Asinh(X);

    switch (comptime types.numericType(X)) {
        .bool => unreachable,
        .int => unreachable,
        .rational => return rational.asinh(x),
        .float => return float.asinh(x),
        .dyadic => return dyadic.asinh(x),
        .complex => return complex.asinh(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "asinh",
                fn (X) numeric.Asinh(X),
                &.{X},
            ) orelse
                @compileError("zsl.numeric.asinh: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn asinh(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.asinh(x);
        },
    }
}
