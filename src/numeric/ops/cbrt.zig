const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Cbrt(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.cbrt: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => @compileError("zml.numeric.cbrt: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zml.numeric.cbrt: not defined for " ++ @typeName(X) ++ "."),
        .rational => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlCbrt", fn (type) type, &.{X}))
                @compileError("zml.numeric.cbrt: " ++ @typeName(X) ++ " must implement `fn ZmlCbrt(type) type`");

            return X.ZmlCbrt(X);
        },
    }
}

/// Returns the cube root `∛x` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.cbrt(x: X) numeric.Cbrt(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the cube root of.
///
/// ## Returns
/// `numeric.Cbrt(@TypeOf(x))`: The cube root of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlCbrt` method. The expected signature and
/// behavior of `ZmlCbrt` are as follows:
/// * `fn ZmlCbrt(type) type`: Returns the type of the cube root of `x`.
///
/// `numeric.Cbrt(X)` or `X` must implement the required `zmlCbrt` method. The
/// expected signature and behavior of `zmlCbrt` are as follows:
/// * `fn zmlCbrt(X) numeric.Cbrt(X)`: Returns the cube root of `x`.
pub inline fn cbrt(x: anytype) numeric.Cbrt(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Cbrt(X);

    switch (comptime types.numericType(X)) {
        .bool => unreachable,
        .int => unreachable,
        .rational => return rational.cbrt(x),
        .float => return float.cbrt(x),
        .dyadic => return dyadic.cbrt(x),
        .complex => return complex.cbrt(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlCbrt",
                fn (X) numeric.Cbrt(X),
                &.{X},
            ) orelse
                @compileError("zml.numeric.cbrt: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlCbrt(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlCbrt(x);
        },
    }
}
