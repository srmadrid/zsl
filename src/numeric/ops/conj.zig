const meta = @import("../../meta.zig");

const int = @import("../../int.zig");
const float = @import("../../float.zig");
const dyadic = @import("../../dyadic.zig");
const complex = @import("../../complex.zig");

const numeric = @import("../../numeric.zig");

pub fn Conj(X: type) type {
    comptime if (!meta.isNumeric(X))
        @compileError("zsl.numeric.conj: x must be a numeric, got \n\tx: " ++ @typeName(X) ++ "\n");

    switch (comptime meta.numericType(X)) {
        .bool => return X,
        .int => return X,
        .float => return X,
        .dyadic => return X,
        .complex => return X,
        .custom => {
            if (comptime !meta.hasMethod(X, "Conj", fn (type) type, &.{X}))
                @compileError("zsl.numeric.conj: " ++ @typeName(X) ++ " must implement `fn Conj(type) type`");

            return X.Conj(X);
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
/// `X` must implement the required `Conj` method. The expected signature and
/// behavior of `Conj` are as follows:
/// * `fn Conj(type) type`: Returns the type of the complex conjugate of `x`.
///
/// `numeric.Conj(X)` or `X` must implement the required `conj` method. The
/// expected signature and behavior of `conj` are as follows:
/// * `fn conj(X) numeric.Conj(X)`: Returns the complex conjugate of `x`.
pub fn conj(x: anytype) numeric.Conj(@TypeOf(x)) {
    const X: type = @TypeOf(x);
    const R: type = numeric.Conj(X);

    switch (comptime meta.numericType(X)) {
        .bool => return x,
        .int => return x,
        .float => return x,
        .dyadic => return x,
        .complex => return x.conj(),
        .custom => {
            const Impl: type = comptime meta.anyHasMethod(
                &.{ R, X },
                "conj",
                fn (X) numeric.Conj(X),
                &.{X},
            ) orelse
                @compileError("zsl.numeric.conj: " ++ @typeName(R) ++ " or " ++ @typeName(X) ++ " must implement `fn conj(" ++ @typeName(X) ++ ") " ++ @typeName(R) ++ "`");

            return Impl.conj(x);
        },
    }
}
