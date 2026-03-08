const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Neg(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.neg: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return X,
        .int => return X,
        .rational => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlNeg", fn (type) type, &.{X}))
                @compileError("zml.numeric.neg: " ++ @typeName(X) ++ " must implement `fn ZmlNeg(type) type`");

            return X.ZmlNeg(X);
        },
    }
}

/// Returns the negation of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.neg(x: X) numeric.Neg(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the negation of.
///
/// ## Returns
/// `numeric.Neg(@TypeOf(x))`: The negation of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlNeg` method. The expected signature and
/// behavior of `ZmlNeg` are as follows:
/// * `fn ZmlNeg(type) type`: Returns the type of the negation of `x`.
///
/// `numeric.Neg(X)` or `X` must implement the required `zmlNeg` method. The
/// expected signature and behavior of `zmlNeg` are as follows:
/// * `fn zmlNeg(X) numeric.Neg(X)`: Returns the negation of `x`.
pub inline fn neg(x: anytype) numeric.Abs(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Neg(X);

    switch (comptime types.numericType(X)) {
        .bool => return x,
        .int => return -x,
        .rational => return rational.neg(x),
        .float => return -x,
        .dyadic => return dyadic.neg(x),
        .complex => return complex.neg(x),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlNeg",
                fn (X) numeric.Neg(X),
                &.{X},
            ) orelse
                @compileError("zml.numeric.neg: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlNeg(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlNeg(x);
        },
    }
}
