const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Cos(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.cos: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => @compileError("zml.numeric.cos: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zml.numeric.cos: not defined for " ++ @typeName(X) ++ "."),
        .rational => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlCos", fn (type) type, &.{X}))
                @compileError("zml.numeric.cos: " ++ @typeName(X) ++ " must implement `fn ZmlCos(type) type`");

            return X.ZmlCos(X);
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
/// `X` must implement the required `ZmlCos` method. The expected signature and
/// behavior of `ZmlCos` are as follows:
/// * `fn ZmlCos(type) type`: Returns the type of the cosine of `x`.
///
/// `numeric.Cos(X)` or `X` must implement the required `zmlCos` method. The
/// expected signature and behavior of `zmlCos` are as follows:
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
                "zmlCos",
                fn (X) numeric.Cos(X),
                &.{X},
            ) orelse
                @compileError("zml.numeric.cos: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlCos(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlCos(x);
        },
    }
}
