const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Acosh(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zsl.numeric.acosh: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => @compileError("zsl.numeric.acosh: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zsl.numeric.acosh: not defined for " ++ @typeName(X) ++ "."),
        .rational => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "Acosh", fn (type) type, &.{X}))
                @compileError("zsl.numeric.acosh: " ++ @typeName(X) ++ " must implement `fn Acosh(type) type`");

            return X.Acosh(X);
        },
    }
}

/// Returns the hyperbolic arccosine `cos⁻¹(x)` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.acosh(x: X) numeric.Acosh(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the hyperbolic arccosine of.
///
/// ## Returns
/// `numeric.Acosh(@TypeOf(x))`: The hyperbolic arccosine of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `Acosh` method. The expected signature and
/// behavior of `Acosh` are as follows:
/// * `fn Acosh(type) type`: Returns the type of the hyperbolic arccosine of
///   `x`.
///
/// `numeric.Acosh(X)` or `X` must implement the required `acosh` method. The
/// expected signature and behavior of `acosh` are as follows:
/// * `fn acosh(X) numeric.Acosh(X)`: Returns the hyperbolic arccosine of `x`.
pub inline fn acosh(x: anytype) numeric.Acosh(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Acosh(X);

    switch (comptime types.numericType(X)) {
        .bool => unreachable,
        .int => unreachable,
        .rational => return rational.acosh(x),
        .float => return float.acosh(x),
        .dyadic => return dyadic.acosh(x),
        .complex => return complex.acosh(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "acosh",
                fn (X) numeric.Acosh(X),
                &.{X},
            ) orelse
                @compileError("zsl.numeric.acosh: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn acosh(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.acosh(x);
        },
    }
}
