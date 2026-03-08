const types = @import("../../types.zig");

const int = @import("../../int.zig");
const rational = @import("../../rational.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Conj(X: type) type {
    comptime if (!types.isNumeric(X))
        @compileError("zml.numeric.conj: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime types.numericType(X)) {
        .bool => return X,
        .int => return X,
        .rational => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !types.hasMethod(X, "ZmlConj", fn (type) type, &.{X}))
                @compileError("zml.numeric.conj: " ++ @typeName(X) ++ " must implement `fn ZmlConj(type) type`");

            return X.ZmlConj(X);
        },
    }
}

/// Returns the complex conjugate of a numeric `x`.
///
/// ## Signature
/// ```zig
/// numeric.conj(x: X) numeric.Conj(X)
/// ```
///
/// ## Arguments
/// * `x` (`anytype`): The numeric value to get the complex conjugate of.
///
/// ## Returns
/// `numeric.Conj(@TypeOf(x))`: The complex conjugate of `x`.
///
/// ## Custom type support
/// This function supports custom numeric types via specific method
/// implementations.
///
/// `X` must implement the required `ZmlConj` method. The expected signature and
/// behavior of `ZmlConj` are as follows:
/// * `fn ZmlConj(type) type`: Returns the type of the complex conjugate of `x`.
///
/// `numeric.Conj(X)` or `X` must implement the required `zmlConj` method. The
/// expected signature and behavior of `zmlConj` are as follows:
/// * `fn zmlConj(X) numeric.Conj(X)`: Returns the complex conjugate of `x`.
pub inline fn conj(x: anytype) numeric.Conj(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Conj(X);

    switch (comptime types.numericType(X)) {
        .bool => return x,
        .int => return x,
        .rational => return x,
        .float => return x,
        .dyadic => return x,
        .complex => return x.conj(),
        .custom => {
            const Impl: type = comptime types.anyHasMethod(
                &.{ R, X },
                "zmlConj",
                fn (X) numeric.Conj(X),
                &.{X},
            ) orelse
                @compileError("zml.numeric.conj: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn zmlConj(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.zmlConj(x);
        },
    }
}
