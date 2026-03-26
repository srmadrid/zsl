const types = @import("../../types.zig");

const int = @import("../../int.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Sqrt(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zsl.numeric.sqrt: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => @compileError("zsl.numeric.sqrt: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zsl.numeric.sqrt: not defined for " ++ @typeName(X) ++ "."),
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "Sqrt", fn (type) type, &.{X}))
                @compileError("zsl.numeric.sqrt: " ++ @typeName(X) ++ " must implement `fn Sqrt(type) type`");

            return X.Sqrt(X);
        },
    }
}

/// Returns the square root `√x` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.sqrt(x: X) numeric.Sqrt(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the square root of.
///
/// ## Returns
/// `numeric.Sqrt(@TypeOf(x))`: The square root of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `Sqrt` method. The expected signature and
/// behavior of `Sqrt` are as follows:
/// * `fn Sqrt(type) type`: Returns the type of the square root of `x`.
///
/// `numeric.Sqrt(X)` or `X` must implement the required `sqrt` method. The
/// expected signature and behavior of `sqrt` are as follows:
/// * `fn sqrt(X) numeric.Sqrt(X)`: Returns the square root of `x`.
pub inline fn sqrt(x: anytype) numeric.Sqrt(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Sqrt(X);

    switch (comptime types.numericType(X)) {
        .bool => unreachable,
        .int => unreachable,
        .float => return float.sqrt(x),
        .dyadic => return dyadic.sqrt(x),
        .complex => return complex.sqrt(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "sqrt",
                fn (X) numeric.Sqrt(X),
                &.{X},
            ) orelse
                @compileError("zsl.numeric.sqrt: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn sqrt(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.sqrt(x);
        },
    }
}
