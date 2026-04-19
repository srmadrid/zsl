const meta = @import("../../meta.zig");

const int = @import("../../int.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Atan(X: type) type {
    comptime if (!meta.isNumeric(X))
        @compileError("zsl.numeric.atan: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime meta.numericType(X)) {
        .bool => @compileError("zsl.numeric.atan: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zsl.numeric.atan: not defined for " ++ @typeName(X) ++ "."),
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !meta.hasMethod(X, "Atan", fn (type) type, &.{X}))
                @compileError("zsl.numeric.atan: " ++ @typeName(X) ++ " must implement `fn Atan(type) type`");

            return X.Atan(X);
        },
    }
}

/// Returns the arctangent `tan⁻¹(x)` of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.atan(x: X) numeric.Atan(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the arctangent of.
///
/// ## Returns
/// `numeric.Atan(@TypeOf(x))`: The arctangent of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `Atan` method. The expected signature and
/// behavior of `Atan` are as follows:
/// * `fn Atan(type) type`: Returns the type of the arctangent of `x`.
///
/// `numeric.Atan(X)` or `X` must implement the required `atan` method. The
/// expected signature and behavior of `atan` are as follows:
/// * `fn atan(X) numeric.Atan(X)`: Returns the arctangent of `x`.
pub fn atan(x: anytype) numeric.Atan(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Atan(X);

    switch (comptime meta.numericType(X)) {
        .bool => unreachable,
        .int => unreachable,
        .float => return float.atan(x),
        .dyadic => return dyadic.atan(x),
        .complex => return complex.atan(x),
        .custom => {
            const Impl: type = comptime meta.anyHasMethod(
                &.{ R, X },
                "atan",
                fn (X) numeric.Atan(X),
                &.{X},
            ) orelse
                @compileError("zsl.numeric.atan: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn atan(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.atan(x);
        },
    }
}
