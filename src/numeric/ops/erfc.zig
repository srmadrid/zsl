const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Erfc(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.erfc: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => @compileError("zml.numeric.erfc: not defined for " ++ @typeName(X) ++ "."),
        .int => @compileError("zml.numeric.erfc: not defined for " ++ @typeName(X) ++ "."),
        .rational => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlErfc", fn (type) type, &.{X}))
                @compileError("zml.numeric.erfc: " ++ @typeName(X) ++ " must implement `fn ZmlErfc(type) type`");

            return X.ZmlErfc(X);
        },
    }
}

/// Returns the complementary error function of a numeric `x`.
///
/// The error function is defined as:
/// $$
/// \mathrm{erfc}(x) = 1 - \frac{2}{\sqrt{\pi}} \int_0^x e^{-t^2} \mathrm{d}t.
/// $$
///
/// ## Signature
/// ```zig
/// numeric.erfc(x: X) numeric.Erfc(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the complementary error function
///   of.
///
/// ## Returns
/// `numeric.Erfc(@TypeOf(x))`: The error function of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlErfc` method. The expected signature and
/// behavior of `ZmlErfc` are as follows:
/// * `fn ZmlErfc(type) type`: Returns the type of the error function of `x`.
///
/// `numeric.Erfc(X)` or `X` must implement the required `zmlErfc` method. The
/// expected signature and behavior of `zmlErfc` are as follows:
/// * `fn zmlErfc(X) numeric.Erfc(X)`: Returns the error function of `x`.
pub inline fn erfc(x: anytype) numeric.Erfc(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Erfc(X);

    switch (comptime types.numericType(X)) {
        .bool => unreachable,
        .int => unreachable,
        .rational => return rational.erfc(x),
        .float => return float.erfc(x),
        .dyadic => return dyadic.erfc(x),
        .complex => return complex.erfc(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlErfc",
                fn (X) numeric.Erfc(X),
                &.{X},
            ) orelse
                @compileError("zml.numeric.erfc: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlErfc(" ++ @typeName(X) ++ " ) " ++ @typeName(R) ++ "`");

            return Impl.zmlErfc(x);
        },
    }
}
